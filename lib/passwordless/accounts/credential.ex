defmodule Passwordless.Accounts.Credential do
  @moduledoc """
  Credentials represent a proof of identity for a user
  and can be used for social login.
  """

  use Passwordless.Schema

  alias Passwordless.Accounts.User

  @providers ~w(google)a

  schema "user_credentials" do
    field :subject, :string
    field :provider, Ecto.Enum, values: @providers

    belongs_to :user, User, type: :binary_id

    timestamps()
  end

  def providers, do: [google: "Google"]

  @fields ~w(
    subject
    provider
    user_id
  )a
  @required_fields @fields

  @doc """
  A user credential changeset.
  """
  def changeset(credential, attrs \\ %{}, _metadata \\ []) do
    credential
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:subject, :provider])
    |> unique_constraint([:user_id, :provider])
    |> unsafe_validate_unique([:subject, :provider], Passwordless.Repo)
    |> unsafe_validate_unique([:user_id, :provider], Passwordless.Repo)
    |> assoc_constraint(:user)
  end
end
