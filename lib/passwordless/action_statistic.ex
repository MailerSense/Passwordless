defmodule Passwordless.ActionStatistic do
  @moduledoc false

  use Passwordless.Schema, prefix: "actstat"

  import Ecto.Query

  alias Database.Tenant
  alias Passwordless.ActionTemplate
  alias Passwordless.App

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :attempts,
      :allows,
      :timeouts,
      :blocks
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "action_statistics" do
    field :attempts, :integer, default: 0
    field :allows, :integer, default: 0
    field :timeouts, :integer, default: 0
    field :blocks, :integer, default: 0

    belongs_to :action_template, ActionTemplate
  end

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
  end

  @fields ~w(
    attempts
    allows
    timeouts
    blocks
    action_template_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action_statistic, attrs \\ %{}) do
    action_statistic
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_number(:attempts, greater_than_or_equal_to: 0)
    |> validate_number(:allows, greater_than_or_equal_to: 0)
    |> validate_number(:timeouts, greater_than_or_equal_to: 0)
    |> validate_number(:blocks, greater_than_or_equal_to: 0)
    |> unique_constraint(:action_template_id)
    |> assoc_constraint(:action_template)
  end
end
