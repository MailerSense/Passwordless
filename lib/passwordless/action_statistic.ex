defmodule Passwordless.ActionStatistic do
  @moduledoc false

  use Passwordless.Schema, prefix: "actstat"

  import Ecto.Query

  alias Database.Tenant
  alias Passwordless.App

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :name,
      :attempts,
      :allowed_attempts,
      :timed_out_attempts,
      :blocked_attempts
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "action_statistics" do
    field :name, :string, virtual: true
    field :attempts, :integer, default: 0
    field :allowed_attempts, :integer, default: 0
    field :timed_out_attempts, :integer, default: 0
    field :blocked_attempts, :integer, default: 0

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
    allowed_attempts
    timed_out_attempts
    blocked_attempts
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
    |> unique_constraint(:action_template_id)
    |> assoc_constraint(:action_template)
  end
end
