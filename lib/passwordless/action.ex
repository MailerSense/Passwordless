defmodule Passwordless.Action do
  @moduledoc """
  An actor avent.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Passwordless.Actor
  alias Passwordless.Project

  @outcomes ~w(allow timeout block challenge)a
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "actions" do
    field :outcome, Ecto.Enum, values: @outcomes

    belongs_to :actor, Actor, type: :binary_id

    timestamps(updated_at: false)
  end

  def outcomes, do: @outcomes

  @doc """
  Get all actions for a project.
  """
  def get_by_project(query \\ __MODULE__, %Project{} = project) do
    from q in query,
      left_join: a in assoc(q, :actor),
      where: a.project_id == ^project.id and is_nil(a.deleted_at)
  end

  @doc """
  Preload associations.
  """
  def preload_actor(query \\ __MODULE__) do
    actor_query =
      from a in Actor,
        select: struct(a, [:id, :first_name, :last_name, :email])

    from q in query, preload: [actor: ^actor_query]
  end

  @doc """
  Get none.
  """
  def get_none(query \\ __MODULE__) do
    from q in query, where: false
  end

  @fields ~w(
    outcome
    actor_id
  )a
  @required_fields @fields

  @doc """
  A contact changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:actor)
  end
end
