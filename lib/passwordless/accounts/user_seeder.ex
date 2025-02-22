defmodule Passwordless.Accounts.UserSeeder do
  @moduledoc """
  Generates dummy users for the development environment.
  """

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Repo

  @password "Qwerty1234!"

  def normal_user(attrs \\ %{}) do
    {:ok, user} = Accounts.register_user(attrs)
    {:ok, user} = Accounts.update_user(user, attrs)
    Accounts.confirm_user!(user)
  end

  def admin(attrs \\ %{}) do
    %{
      kind: :user,
      state: :active,
      name: "John Smith",
      email: "marcin.praski@mailersend.com",
      password: @password
    }
    |> Map.merge(attrs)
    |> normal_user()
  end

  def random_user(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> random_user_attributes()
      |> Accounts.register_user()

    user
  end

  # Use this for quickly inserting large numbers of users
  # We use insert_all to avoid hashing passwords one by one, which is slow
  def random_users(count) do
    now = DateTime.utc_now()

    users_data =
      Enum.map(1..count, fn _ ->
        Map.merge(random_user_attributes(), %{
          inserted_at: now,
          updated_at: now,
          confirmed_at: Enum.random([now, now, now, nil])
        })
      end)

    for user <- users_data do
      Repo.insert(User.registration_changeset(%User{}, user))
    end
  end

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def random_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: Faker.Person.En.first_name() <> " " <> Faker.Person.En.last_name(),
      email: unique_user_email(),
      password: @password
    })
  end
end
