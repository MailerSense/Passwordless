defmodule Passwordless.SecurityKey do
  @moduledoc """
  A WebAuthn identity.
  """

  use Passwordless.Schema, prefix: "seckey"

  alias Passwordless.Actor
  alias Passwordless.App

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: [], adapter_opts: []
  }
  schema "security_key_holders" do
    field :handle, :string

    belongs_to :app, App
    belongs_to :actor, Actor

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    handle
    app_id
    actor_id
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
    |> assoc_constraint(:actor)
  end
end
