defmodule Passwordless.Action do
  @moduledoc """
  An actor avent.
  """

  use Passwordless.Schema, prefix: "actn"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.ActionEvent
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Challenge
  alias Passwordless.Rule

  @states ~w(allow timeout block pending)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "actions" do
    field :name, :string
    field :state, Ecto.Enum, values: @states

    has_one :challenge, Challenge, where: [current: true]

    has_many :challenges, Challenge
    has_many :action_events, ActionEvent

    belongs_to :rule, Rule
    belongs_to :actor, Actor

    timestamps()
  end

  def states, do: @states

  def topic_for(%App{} = app), do: "#{prefix()}:#{app.id}"

  def first_event(%__MODULE__{action_events: [_ | _] = events}) do
    events
    |> Enum.sort_by(& &1.inserted_at, :asc)
    |> Enum.find(fn %ActionEvent{city: city, country: country} ->
      is_binary(city) and is_binary(country)
    end)
  end

  def first_event(%__MODULE__{}), do: nil

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Database.Tenant.to_prefix(app)
  end

  @doc """
  Get by actor.
  """
  def get_by_actor(query \\ __MODULE__, %App{} = app, %Actor{} = actor) do
    from q in query, prefix: ^Database.Tenant.to_prefix(app), where: q.actor_id == ^actor.id
  end

  @doc """
  Get by states.
  """
  def get_by_states(query \\ __MODULE__, states) do
    from q in query, where: q.state in ^states
  end

  @doc """
  Preload associations.
  """
  def preload_actor(query \\ __MODULE__) do
    from q in query, preload: [:events, actor: [:email, :phone]]
  end

  @fields ~w(
    name
    flow
    state
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
    |> validate_name()
    |> validate_state()
    |> assoc_constraint(:actor)
  end

  @doc """
  A state changeset.
  """
  def state_changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, [:state])
    |> validate_required([:state])
    |> validate_state()
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 255)
  end

  defp validate_state(changeset) do
    ChangesetExt.validate_state(changeset, pending: [:allow, :timeout, :block])
  end
end
