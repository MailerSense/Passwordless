defmodule Passwordless.Methods.Authenticator do
  @moduledoc """
  An Authenticator method.
  """

  use Passwordless.Schema

  alias Passwordless.App

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: [], adapter_opts: []
  }
  schema "authenticator_methods" do
    field :enabled, :boolean, default: true
    field :issuer_name, :string
    field :hide_download_screen, :boolean, default: false

    belongs_to :app, App, type: :binary_id

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
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:app)
  end
end
