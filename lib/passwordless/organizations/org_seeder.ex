defmodule Passwordless.Organizations.OrgSeeder do
  @moduledoc """
  Generates dummy orgs for the development environment.
  """

  alias Database.Tenant
  alias Passwordless.Accounts.User
  alias Passwordless.Action
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
    attrs = Map.merge(random_org_attributes(), attrs)
    attrs = Map.put(attrs, :name, "Passwordless GmbH")
    attrs = Map.put(attrs, :tags, [:admin])

    {:ok, org, _membership} = Organizations.create_org_with_owner(user, attrs)

    {:ok, app} =
      Passwordless.create_app(org, %{
        "name" => "Demo App",
        "website" => "https://passwordless.tools",
        "display_name" => "Demo App"
      })

    {:ok, domain} =
      Passwordless.create_domain(app, %{
        name: "auth.passwordlesstools.com",
        kind: :sub_domain
      })

    {:ok, magic_link_template} = Passwordless.seed_email_template(app, :magic_link_sign_in, :en)
    {:ok, email_otp_template} = Passwordless.seed_email_template(app, :email_otp_sign_in, :en)

    {:ok, _methods} =
      Passwordless.create_methods(app, %{
        magic_link: %{
          sender: "verify",
          sender_name: app.name,
          domain_id: domain.id,
          email_template_id: magic_link_template.id,
          redirect_urls: [%{url: app.website}]
        },
        email: %{
          sender: "verify",
          sender_name: app.name,
          domain_id: domain.id,
          email_template_id: email_otp_template.id
        },
        authenticator: %{
          issuer_name: app.name
        },
        security_key: %{
          relying_party_id: URI.parse(app.website).host,
          expected_origins: [%{url: app.website}]
        },
        passkey: %{
          relying_party_id: URI.parse(app.website).host,
          expected_origins: [%{url: app.website}]
        }
      })

    for r <- default_domain_records(domain.name) do
      {:ok, _} = Passwordless.create_domain_record(domain, r)
    end

    {:ok, _tenant} = Tenant.create(app)

    for {email, phone} <- @random_emails |> Stream.zip(@random_phones) |> Enum.take(1_000) do
      {:ok, actor} =
        Passwordless.create_actor(app, %{
          name: Faker.Person.name(),
          state: Util.pick(active: 80, locked: 20),
          system_id: UUIDv7.autogenerate(),
          properties: %{
            "email" => email,
            "phone" => phone
          }
        })

      {:ok, _email} =
        Passwordless.add_email(app, actor, %{
          address: email,
          primary: true,
          verified: true
        })

      {:ok, _phone} =
        Passwordless.add_regional_phone(app, actor, %{
          region: "US",
          number: phone,
          primary: true,
          verified: true
        })

      {:ok, _identity} =
        Passwordless.add_identity(app, actor, %{
          system: "internal",
          user_id: UUIDv7.autogenerate()
        })

      {:ok, _recovery_codes} = Passwordless.create_actor_recovery_codes(app, actor)

      for _ <- 1..1 do
        {:ok, _action} =
          Passwordless.create_action(app, actor, %{
            name: Enum.random(~w(signIn withdraw placeOrder)),
            method: Enum.random(Passwordless.methods()),
            outcome: Enum.random(Action.outcomes())
          })
      end
    end

    org
  end

  # Private

  defp random_org_attributes do
    %{
      name: Faker.Company.name(),
      email: Enum.random(@random_emails)
    }
  end

  defp default_domain_records(domain) do
    {:ok, %{subdomain: subdomain}} = Domainatrex.parse(domain)

    [
      %{kind: :txt, name: "envelope.#{subdomain}", value: "v=spf1 include:amazonses.com ~all"},
      %{
        kind: :txt,
        name: "envelope.#{subdomain}",
        value: "v=DMARC1; p=none; rua=mailto:dmarc@mailersense.com;"
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
