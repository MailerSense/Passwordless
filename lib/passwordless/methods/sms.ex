defmodule Passwordless.Methods.SMS do
  @moduledoc """
  An SMS method.
  """

  use Passwordless.Schema

  alias Passwordless.App

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: [], adapter_opts: []
  }
  schema "sms_methods" do
    field :enabled, :boolean, default: true

    belongs_to :app, App, type: :binary_id

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
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end
end
