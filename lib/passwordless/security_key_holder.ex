defmodule Passwordless.SecurityKey do
  @moduledoc """
  A WebAuthn credential.
  """

  use Passwordless.Schema

  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.SecurityKeyHolder

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: [], adapter_opts: []
  }
  schema "security_keys" do
    belongs_to :app, App, type: :binary_id
    belongs_to :actor, Actor, type: :binary_id
    belongs_to :security_key_holder, SecurityKeyHolder, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    app_id
    actor_id
    security_key_holder_id
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
    |> assoc_constraint(:security_key_holder)
  end
end
