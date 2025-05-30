defmodule Passwordless.Authenticators.Social do
  @moduledoc """
  A social authenticator.
  """

  use Passwordless.Schema, prefix: "social"

  alias Passwordless.App

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :enabled,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "social_authenticators" do
    field :enabled, :boolean, default: true

    belongs_to :app, App

    timestamps()
  end

  @fields ~w(
    enabled
    app_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = totp, attrs \\ %{}, _opts \\ []) do
    totp
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end
end
