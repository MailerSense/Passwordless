defmodule Passwordless.Rule do
  @moduledoc """
  An action behaviour.
  """

  use Passwordless.Schema, prefix: "rule"

  alias Passwordless.Action

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "rules" do
    field :condition, :map, default: %{}
    field :effects, :map, default: %{}

    has_many :actions, Action

    timestamps()
  end
end
