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
    attrs = Map.merge(random_org_attributes(), attrs)
    attrs = Map.put(attrs, :name, "Passwordless GmbH")
    attrs = Map.put(attrs, :tags, [:admin])

    {:ok, org, _membership} = Organizations.create_org_with_owner(user, attrs)

    {:ok, auth_token, _signed_auth_token} =
      Organizations.create_auth_token(org, %{"name" => "Github Actions", "scopes" => [:sync]})

    Logger.info("----------- AUTH TOKEN ------------")
    Logger.info(auth_token)

    {:ok, project} =
      Passwordless.create_project(org, %{
        "name" => "Demo Project",
        "description" => "Demo Project Description"
      })

    org
  end

  def root_org_local(%User{} = user, attrs \\ %{}) do
    attrs = Map.merge(random_org_attributes(), attrs)
    attrs = Map.put(attrs, :name, "Passwordless GmbH")
    attrs = Map.put(attrs, :tags, [:admin])

    {:ok, org, _membership} = Organizations.create_org_with_owner(user, attrs)

    {:ok, auth_token, _signed_auth_token} =
      Organizations.create_auth_token(org, %{"name" => "Github Actions", "scopes" => [:sync]})

    Logger.info("----------- AUTH TOKEN ------------")
    Logger.info(auth_token)

    {:ok, project} =
      Passwordless.create_project(org, %{
        "name" => "Demo Project",
        "description" => "Demo Project Description"
      })

    for {email, phone} <- @random_emails |> Stream.zip(@random_phones) |> Enum.take(1000) do
      {:ok, actor} =
        Passwordless.create_actor(project, %{
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

  defp random_check_attributes do
    %{
      name: "Check " <> Faker.Pokemon.name(),
      state: Enum.random(for(_ <- 1..10, do: :online) ++ ~w(warning down)a)
    }
  end

  defp random_org_attributes do
    %{
      name: Faker.Company.name(),
      email: Enum.random(@random_emails)
    }
  end

  defp random_data_entry_schema do
    Faker.App.name() |> Slug.slugify() |> String.replace(~r/-/, "_") |> String.to_atom()

    %{
      name: Faker.Company.name(),
      email: Enum.random(@random_emails)
    }
  end
end
