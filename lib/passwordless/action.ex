defmodule Passwordless.Action do
  @moduledoc """
  An actor avent.
  """

  use Passwordless.Schema

  import Ecto.Query
  import PolymorphicEmbed

  alias Passwordless.ActionEvent
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Flows

  @flows ~w(email)a
  @states ~w(allow timeout block pending)a
  @authenticators ~w(email sms whatsapp magic_link totp security_key passkey recovery_codes)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id, :state, :inserted_at]
  }
  schema "actions" do
    field :name, :string
    field :flow, Ecto.Enum, values: @flows
    field :state, Ecto.Enum, values: @states
    field :authenticator, Ecto.Enum, values: @authenticators

    polymorphic_embeds_one(:data,
      types: [
        email: Flows.Email
      ],
      use_parent_field_for_type: :flow,
      on_type_not_found: :raise,
      on_replace: :update
    )

    has_many :events, ActionEvent

    belongs_to :actor, Actor, type: :binary_id

    timestamps()
  end

  def flows, do: @flows
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
    flow
    state
    authenticator
    actor_id
  )a
  @required_fields @fields -- [:authenticator]

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:actor)
    |> cast_polymorphic_embed(:data, required: true)
  end
end
