defmodule Passwordless.SecurityKey do
  @moduledoc """
  A WebAuthn identity.
  """

  use Passwordless.Schema, prefix: "seckey"

  alias Passwordless.App
  alias Passwordless.User

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: [], adapter_opts: []
  }
  schema "security_key_holders" do
    field :handle, :string

    belongs_to :app, App
    belongs_to :user, User

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    handle
    app_id
    user_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = security_key, attrs \\ %{}) do
    security_key
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:app)
    |> assoc_constraint(:user)
  end
end
