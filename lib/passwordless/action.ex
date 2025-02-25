defmodule Passwordless.Action do
  @moduledoc """
  An actor avent.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Challenge

  @outcomes ~w(allow timeout block challenge)a
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "actions" do
    field :name, :string
    field :method, Ecto.Enum, values: Passwordless.methods()
    field :outcome, Ecto.Enum, values: @outcomes

    has_one :challenge, Challenge

    belongs_to :app, App, type: :binary_id
    belongs_to :actor, Actor, type: :binary_id

    timestamps()
  end

  def outcomes, do: @outcomes

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, where: q.app_id == ^app.id
  end

  @doc """
  Get by actor.
  """
  def get_by_actor(query \\ __MODULE__, %Actor{} = actor) do
    from q in query, where: q.actor_id == ^actor.id
  end

  @doc """
  Preload associations.
  """
  def preload_actor(query \\ __MODULE__) do
    from q in query, preload: [actor: [:email, :phone]]
  end

  @fields ~w(
    name
    method
    outcome
    app_id
    actor_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:app)
    |> assoc_constraint(:actor)
  end
end
