defmodule Passwordless.Rule do
  @moduledoc """
  An action behaviour.
  """

  use Passwordless.Schema, prefix: "rule"

  alias Passwordless.Action

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :condition,
      :effects,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "rules" do
    field :condition, :map, default: %{}
    field :effects, :map, default: %{}

    has_many :actions, Action, preload_order: [asc: :inserted_at]

    timestamps()
  end

  @fields ~w(
    condition
    effects
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
