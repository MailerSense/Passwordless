defmodule Passwordless.Authenticators.RecoveryCodes do
  @moduledoc """
  An recovery codes authenticator.
  """

  use Passwordless.Schema, prefix: "recovery_codes"

  alias Passwordless.App

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :enabled,
      :hide_on_enrollment,
      :skip_on_programatic,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "recovery_codes_authenticators" do
    field :enabled, :boolean, default: true
    field :hide_on_enrollment, :boolean, default: false
    field :skip_on_programatic, :boolean, default: false

    belongs_to :app, App

    timestamps()
  end

  @fields ~w(
    enabled
    hide_on_enrollment
    skip_on_programatic
    app_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = recovery_codes, attrs \\ %{}, opts \\ []) do
    recovery_codes
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end
end
