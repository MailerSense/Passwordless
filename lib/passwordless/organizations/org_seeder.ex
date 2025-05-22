defmodule Passwordless.Organizations.OrgSeeder do
  @moduledoc """
  Generates dummy orgs for the development environment.
  """

  alias Database.Tenant
  alias Passwordless.Accounts.User, as: AccountsUser
  alias Passwordless.Action
  alias Passwordless.AuthToken
  alias Passwordless.Challenge
  alias Passwordless.Organizations

  require Logger

  @random_ips ~w(
    23.192.228.80
    78.30.102.205
  )

  @random_emails fn -> Slug.slugify(Faker.Person.name()) <> "." <> Util.random_string(6) end
                 |> Stream.repeatedly()
                 |> Stream.take(10_000)
                 |> Stream.map(&(&1 <> "@gmail.com"))
                 |> Enum.to_list()

  @random_phones (&Faker.Phone.EnUs.phone/0)
                 |> Stream.repeatedly()
                 |> Stream.uniq()
                 |> Stream.take(10_000)
                 |> Enum.to_list()

  @random_actions fn -> Enum.random(["Sign In", "Withdraw Money", "Place Order", "See Data"]) end
                  |> Stream.repeatedly()
                  |> Stream.take(10)
                  |> Stream.uniq()
                  |> Enum.to_list()

  def root_org(%AccountsUser{} = user, opts \\ []) do
    root_org_local(user, opts)
  end

  def root_org_local(%AccountsUser{} = user, opts \\ []) do
    {:ok, org, _membership} =
      Organizations.create_org_with_owner(user, %{
        tags: [:system, :default, :admin],
        name: "OpenTide GmbH",
        email: "passwordless@opentide.com"
      })

    {:ok, app} =
      Passwordless.create_app(org, %{
        name: Passwordless.config(:app_name),
        settings: %{
          logo: Passwordless.config(:app_logo),
          website: "https://passwordless.tools",
          display_name: Passwordless.config(:app_name),
          email_tracking: true,
          email_configuration_set: "passwordless-tools-app-ses-config-set",
          email_event_destination: "passwordless-tools-app-ses-notification-destination",
          email_event_topic_arn: "arn:aws:sns:eu-west-1:728247919352:passwordless-tools-app-ses-email-topic",
          email_event_topic_subscription_arn:
            "arn:aws:sns:eu-west-1:728247919352:passwordless-tools-app-ses-email-topic:5760c1f3-9656-44c2-883a-b961b08dbdfa",
          allowlisted_ip_addresses: [
            %{address: "0.0.0.0/0"}
          ]
        }
      })

    {:ok, auth_token} = Passwordless.create_auth_token(app, %{permissions: [:actions]})

    Logger.warning("----------- AUTH TOKEN ------------")
    Logger.warning(AuthToken.encode(auth_token))

    {:ok, domain} =
      Passwordless.create_email_domain(app, %{
        name: "auth.eu.passwordlesstools.com",
        kind: :sub_domain,
        tags: [:system, :default],
        purpose: :email,
        verified: true
      })

    {:ok, _tracking_domain} =
      Passwordless.create_tracking_domain(app, %{
        name: "click.eu.passwordlesstools.com",
        kind: :sub_domain,
        tags: [:system, :default],
        purpose: :tracking
      })

    {:ok, magic_link_template} =
      Passwordless.seed_email_template(app, :magic_link, :en, :magic_link_clean, %{tags: [:magic_link]})

    {:ok, email_otp_template} =
      Passwordless.seed_email_template(app, :email_otp, :en, :email_otp_clean, %{tags: [:email_otp]})

    {:ok, _authenticators} =
      Passwordless.create_authenticators(app, %{
        magic_link: %{
          sender: "verify",
          sender_name: app.name,
          email_template_id: magic_link_template.id,
          redirect_urls: [%{url: app.settings.website}]
        },
        email_otp: %{
          sender: "verify",
          sender_name: app.name,
          email_template_id: email_otp_template.id
        },
        totp: %{
          issuer_name: app.name
        },
        security_key: %{
          relying_party_id: URI.parse(app.settings.website).host,
          expected_origins: [%{url: app.settings.website}]
        },
        passkey: %{
          relying_party_id: URI.parse(app.settings.website).host,
          expected_origins: [%{url: app.settings.website}]
        }
      })

    for r <- default_domain_records(domain.name) do
      {:ok, _} = Passwordless.create_domain_record(domain, r)
    end

    {:ok, _tenant} = Tenant.create(app)

    templates =
      for name <- @random_actions do
        {:ok, t} =
          Passwordless.create_action_template(app, %{
            name: name,
            rules: [
              %{
                index: 0,
                enabled: true,
                condition: %{},
                effects: %{}
              },
              %{
                index: 1,
                enabled: true,
                condition: %{},
                effects: %{}
              },
              %{
                index: 2,
                enabled: true,
                condition: %{},
                effects: %{}
              }
            ]
          })

        t
      end

    users_count = Keyword.get(opts, :users, 50)
    actions_count = Keyword.get(opts, :actions, 5)

    for {email, phone} <- @random_emails |> Stream.zip(@random_phones) |> Enum.take(users_count) do
      {:ok, app_user} =
        Passwordless.create_user(app, %{
          data: %{
            "email" => email,
            "phone" => phone
          }
        })

      {:ok, _email} =
        Passwordless.add_user_email(app, app_user, %{
          address: email,
          primary: true,
          verified: true,
          authenticators: [:email_otp]
        })

      {:ok, _phone} =
        Passwordless.add_user_regional_phone(app, app_user, %{
          region: "US",
          number: phone,
          primary: true,
          verified: true
        })

      {:ok, _recovery_codes} = Passwordless.create_user_recovery_codes(app, app_user)

      {:ok, mem_rule} =
        Passwordless.RuleEngine.parse(%{
          if: %{
            "or" => [
              true,
              %{
                "ip_address" => %{
                  "country_code" => "DE"
                }
              }
            ]
          },
          then: []
        })

      for _ <- 1..actions_count do
        {:ok, action} =
          Passwordless.create_action(app, app_user, %{
            data: %{"some" => "body"},
            state: Enum.random(Action.states()),
            action_template_id: Enum.random(templates).id
          })

        {:ok, _update} = Passwordless.update_action_statistic(app, action)

        {:ok, challenge} =
          Passwordless.create_challenge(app, action, %{
            kind: Enum.random(Challenge.kinds()),
            state: :started,
            current: true,
            options: [
              %{
                name: "validate_email_otp",
                info: %{
                  "email" => "m******@opentide.com"
                }
              },
              %{
                name: "resend_email_otp",
                info: %{
                  "email" => "m******@opentide.com"
                }
              }
            ]
          })

        {:ok, _challenge_token} = Passwordless.create_challenge_token(app, challenge)

        {:ok, _event} =
          Passwordless.create_event(app, app_user, %{
            event: "send_otp",
            metadata: %{
              before: %{
                code: "123456",
                state: :started,
                attempts: 0
              },
              after: %{
                code: "123456",
                state: :started,
                attempts: 0
              },
              attrs: %{
                code: "123456",
                state: :started,
                attempts: 0
              }
            },
            user_agent: Faker.Internet.UserAgent.desktop_user_agent(),
            ip_address: Enum.random(@random_ips),
            action_id: action.id
          })
      end
    end

    org
  end

  # Private

  defp default_domain_records(domain) do
    {:ok, %{subdomain: subdomain}} = Domainatrex.parse(domain)

    [
      %{
        kind: :mx,
        name: "email.#{subdomain}",
        value: "feedback-smtp.eu-west-1.amazonses.com",
        verified: true,
        priority: 10
      },
      %{kind: :txt, name: "email.#{subdomain}", value: "v=spf1 include:amazonses.com ~all", verified: true},
      %{
        kind: :txt,
        name: "_dmarc.#{subdomain}",
        value: "v=DMARC1; p=none; rua=mailto:dmarc@mailersense.com;",
        verified: true
      },
      %{
        kind: :cname,
        name: "6gofkzgsmtm3puhejogwvpq4hdulyhbt._domainkey.#{subdomain}",
        value: "6gofkzgsmtm3puhejogwvpq4hdulyhbt.dkim.amazonses.com",
        verified: true
      },
      %{
        kind: :cname,
        name: "4pjglljley3rptdd6x6jiukdffssnfj4._domainkey.#{subdomain}",
        value: "4pjglljley3rptdd6x6jiukdffssnfj4.dkim.amazonses.com",
        verified: true
      },
      %{
        kind: :cname,
        name: "vons5ikwlowq2o4k53modgl3wtfi4eqd._domainkey.#{subdomain}",
        value: "vons5ikwlowq2o4k53modgl3wtfi4eqd.dkim.amazonses.com",
        verified: true
      }
    ]
  end
end
