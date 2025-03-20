defmodule Passwordless.Action do
  @moduledoc """
  An actor avent.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Event

  @states ~w(allow timeout block challenge_required)a
  @methods ~w(email sms whatsapp magic_link authenticator security_key passkey recovery_codes)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id, :state, :inserted_at]
  }
  schema "actions" do
    field :name, :string
    field :state, Ecto.Enum, values: @states, default: :challenge_required
    field :token, :binary, redact: true
    field :method, Ecto.Enum, values: @methods
    field :attempts, :integer, default: 0
    field :expires_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec

    has_many :events, Event

    belongs_to :actor, Actor, type: :binary_id

    timestamps()
  end

  def states, do: @states
  def methods, do: @methods

  def topic_for(%App{} = app), do: "actions:#{app.id}"

  def first_event(%__MODULE__{events: [_ | _] = events}) do
    events
    |> Enum.sort_by(& &1.inserted_at, :asc)
    |> Enum.find(fn %Event{city: city, country: country} -> is_binary(city) and is_binary(country) end)
  end

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
    state
    token
    method
    attempts
    expires_at
    completed_at
    actor_id
  )a
  @required_fields ~w(
    name
    state
    attempts
    actor_id
  )a

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:actor)
  end
end
