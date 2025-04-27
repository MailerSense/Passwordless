defmodule Passwordless.Authenticators.TOTP do
  @moduledoc """
  A TOTP authenticator.
  """

  use Passwordless.Schema, prefix: "totp"

  alias Passwordless.App

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :enabled,
      :issuer_name,
      :hide_download_screen,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "totp_authenticators" do
    field :enabled, :boolean, default: true
    field :issuer_name, :string
    field :hide_download_screen, :boolean, default: false

    belongs_to :app, App

    timestamps()
  end

  @fields ~w(
    enabled
    issuer_name
    hide_download_screen
    app_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}, _opts \\ []) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end
end
