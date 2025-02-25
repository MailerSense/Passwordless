defmodule Passwordless.Organizations.OrgSeeder do
  @moduledoc """
  Generates dummy orgs for the development environment.
  """

  alias Passwordless.Accounts.User
  alias Passwordless.Action
  alias Passwordless.Actor
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
        "description" => "Demo App Description"
      })

    {:ok, _methods} = Passwordless.create_methods(app)

    for {email, phone} <- @random_emails |> Stream.zip(@random_phones) |> Enum.take(2_000) do
      {:ok, actor} =
        Passwordless.create_actor(app, %{
          name: Faker.Person.name(),
          state: Enum.random(Actor.states())
        })

      {:ok, _email} =
        Passwordless.add_email(actor, %{
          address: email,
          primary: true,
          verified: true
        })

      {:ok, _phone} =
        Passwordless.add_phone(actor, %{
          address: phone,
          primary: true,
          verified: true
        })

      for _ <- 1..1 do
        {:ok, _action} =
          Passwordless.create_action(actor, %{
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
end
