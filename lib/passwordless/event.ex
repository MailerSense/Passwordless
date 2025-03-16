defmodule Passwordless.Event do
  @moduledoc """
  An actor avent.
  """

  use Passwordless.Schema

  alias Passwordless.Action

  @kinds ~w(initiated)a
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "events" do
    field :kind, Ecto.Enum, values: @kinds, default: :initiated
    field :ip_address, :string
    field :country, :string
    field :city, :string

    belongs_to :action, Action

    timestamps(updated_at: false)
  end

  @fields ~w(
    kind
    ip_address
    country
    city
    action_id
  )a
  @required_fields ~w(
    kind
    action_id
  )a

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:action)
  end
end
