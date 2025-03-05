defmodule Passwordless.Methods.RecoveryCodes do
  @moduledoc """
  An recovery codes method.
  """

  use Passwordless.Schema

  alias Passwordless.App

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "recovery_codes_methods" do
    field :enabled, :boolean, default: true
    field :hide_on_enrollment, :boolean, default: false
    field :skip_on_programatic, :boolean, default: false

    belongs_to :app, App, type: :binary_id

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
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end
end
