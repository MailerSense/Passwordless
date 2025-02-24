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

    for {email, phone} <- @random_emails |> Stream.zip(@random_phones) |> Enum.take(1000) do
      {:ok, actor} =
        Passwordless.create_actor(app, %{
          first_name: Faker.Person.first_name(),
          last_name: Faker.Person.last_name(),
          email: email,
          phone: phone,
          state: Enum.random(Actor.states())
        })

      for _ <- 1..1 do
        {:ok, _action} =
          Passwordless.create_action(actor, %{
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
