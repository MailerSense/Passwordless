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
    field :hash, :binary
    field :condition, :map, default: %{}
    field :effects, {:array, :map}, default: []

    has_many :actions, Action, preload_order: [asc: :inserted_at]

    timestamps()
  end

  def hash(%__MODULE__{} = mod) do
    :crypto.hash(:sha256, :erlang.term_to_binary({mod.condition, mod.effects}))
  end

  @fields ~w(
    hash
    condition
    effects
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = rule, attrs \\ %{}) do
    rule
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
