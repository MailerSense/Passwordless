defmodule Passwordless.Action do
  @moduledoc """
  An actor avent.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Passwordless.ActionEvent
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Flows

  @states ~w(allow timeout block challenge_required)a
  @authenticators ~w(email sms whatsapp magic_link totp security_key passkey recovery_codes)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id, :state, :inserted_at]
  }
  schema "actions" do
    field :name, :string
    field :flow, Ecto.Enum, values: Flows.all_flows(), default: :email_otp
    field :state, Ecto.Enum, values: Flows.all_states(), default: :started
    field :nonce, :binary

    field :code, :string
    field :attempts, :integer, default: 0
    field :expires_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec
    field :authenticator, Ecto.Enum, values: @authenticators

    has_many :events, ActionEvent

    belongs_to :actor, Actor, type: :binary_id

    timestamps()
  end

  def states, do: @states
  def authenticators, do: @authenticators

  def topic_for(%App{} = app), do: "actions:#{app.id}"

  def first_event(%__MODULE__{events: [_ | _] = events}) do
    events
    |> Enum.sort_by(& &1.inserted_at, :asc)
    |> Enum.find(fn %ActionEvent{city: city, country: country} ->
      is_binary(city) and is_binary(country)
    end)
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
    attempts
    expires_at
    completed_at
    authenticator
    actor_id
  )a
  @required_fields ~w(
    name
    state
    attempts
    authenticator
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
