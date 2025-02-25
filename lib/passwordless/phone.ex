defmodule Passwordless.Phone do
  @moduledoc """
  A phone.
  """

  use Passwordless.Schema

  alias Passwordless.Actor
  alias Passwordless.App

  @channels ~w(sms whatsapp)a
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: [], adapter_opts: []
  }
  schema "phones" do
    field :address, :string
    field :primary, :boolean, default: false
    field :verified, :boolean, default: false
    field :channels, {:array, Ecto.Enum}, values: @channels, default: []

    belongs_to :app, App, type: :binary_id
    belongs_to :actor, Actor, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    address
    primary
    verified
    channels
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
    |> unique_constraint([:app_id, :address], error_key: :address)
    |> unique_constraint([:app_id, :actor_id, :primary], error_key: :primary)
    |> unique_constraint([:app_id, :actor_id, :address], error_key: :address)
    |> unsafe_validate_unique([:app_id, :address], Passwordless.Repo, error_key: :address)
    |> unsafe_validate_unique([:app_id, :actor_id, :primary], Passwordless.Repo, error_key: :primary)
    |> unsafe_validate_unique([:app_id, :actor_id, :address], Passwordless.Repo, error_key: :address)
    |> assoc_constraint(:app)
    |> assoc_constraint(:actor)
  end

  # Private
end
