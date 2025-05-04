defmodule Passwordless.Organizations.OrgSeeder do
  @moduledoc """
  Generates dummy orgs for the development environment.
  """

  alias Database.Tenant
  alias Passwordless.Accounts.User
  alias Passwordless.Action
  alias Passwordless.AuthToken
  alias Passwordless.Challenge
  alias Passwordless.Organizations

  require Logger

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

  def root_org(%User{} = user, attrs \\ %{}) do
    root_org_local(user, attrs)
  end

  def root_org_local(%User{} = user, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          tags: [:system, :default, :admin],
          name: "OpenTide GmbH",
          email: "passwordless@opentide.com"
        },
        attrs
      )

    {:ok, org, _membership} = Organizations.create_org_with_owner(user, attrs)

    {:ok, app} =
      Passwordless.create_app(org, %{
        name: "Demo App",
        settings: %{
          logo: "https://cdn.passwordlesstools.com/logos/passwordless.png",
          website: "https://passwordless.tools",
          display_name: "Demo App",
          email_tracking: true,
          email_configuration_set: "passwordless-tools-app-ses-config-set",
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

    {:ok, tracking_domain} =
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

    for {email, phone} <- @random_emails |> Stream.zip(@random_phones) |> Enum.take(1_00) do
      {:ok, actor} =
        Passwordless.create_actor(app, %{
          name: Faker.Person.name(),
          state: Util.pick(active: 80, locked: 20),
          username: Uniq.UUID.uuid7(),
          properties: %{
            "email" => email,
            "phone" => phone
          }
        })

      {:ok, _email} =
        Passwordless.add_email(app, actor, %{
          address: email,
          primary: true,
          verified: true,
          authenticators: [:email_otp]
        })

      {:ok, _phone} =
        Passwordless.add_regional_phone(app, actor, %{
          region: "US",
          number: phone,
          primary: true,
          verified: true
        })

      {:ok, _recovery_codes} = Passwordless.create_actor_recovery_codes(app, actor)

      {:ok, rule} =
        Passwordless.create_rule(app, %{
          conditions: %{},
          effects: %{}
        })

      for _ <- 1..10 do
        {:ok, action} =
          Passwordless.create_action(app, actor, %{
            name: Enum.random(~w(signIn withdraw placeOrder)),
            data: %{"some" => "body"},
            state: Enum.random(Action.states()),
            rule_id: rule.id
          })

        {:ok, _challenge} =
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

        {:ok, _event} =
          Passwordless.create_event(app, action, %{
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
            ip_address: Faker.Internet.ip_v4_address(),
            country: Faker.Address.country_code(),
            city: Faker.Address.city()
          })
      end
    end

    org
  end

  # Private

  defp default_domain_records(domain) do
    {:ok, %{subdomain: subdomain}} = Domainatrex.parse(domain)

    [
      %{kind: :txt, name: "envelope.#{subdomain}", value: "v=spf1 include:amazonses.com ~all", verified: true},
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
