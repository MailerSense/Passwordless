defmodule Passwordless.Action do
  @moduledoc """
  An action.
  """

  use Passwordless.Schema, prefix: "action"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Database.Tenant
  alias Passwordless.App
  alias Passwordless.Challenge
  alias Passwordless.Event
  alias Passwordless.Rule
  alias Passwordless.User

  @states ~w(allow timeout block pending)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :data,
      :name,
      :state,
      :challenge,
      :events,
      :user,
      :rule,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "actions" do
    field :name, :string
    field :data, Passwordless.EncryptedMap
    field :state, Ecto.Enum, values: @states, default: :pending

    has_one :challenge, Challenge, where: [current: true]

    has_many :events, Event, preload_order: [asc: :inserted_at]
    has_many :challenges, Challenge, preload_order: [asc: :inserted_at]

    belongs_to :rule, Rule
    belongs_to :user, User

    timestamps()
  end

  def states, do: @states

  def topic_for(%App{} = app), do: "#{prefix()}:#{app.id}"

  def preloads, do: [:rule, {:user, [:totps, :email, :emails, :phone, :phones]}, {:challenge, [:email_message]}, :events]

  def readable_name(%__MODULE__{name: name}), do: Recase.to_sentence(name)

  def first_event(%__MODULE__{events: [_ | _] = events}) do
    events
    |> Enum.sort_by(& &1.inserted_at, :asc)
    |> Enum.find(fn %Event{city: city, country: country} ->
      is_binary(city) and is_binary(country)
    end)
  end

  def first_event(%__MODULE__{}), do: nil

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
  end

  @doc """
  Get where user is present.
  """
  def where_user_is_present(query \\ __MODULE__) do
    from q in query, where: not is_nil(q.user_id)
  end

  @doc """
  Get by user.
  """
  def get_by_user(query \\ __MODULE__, %App{} = app, %User{} = user) do
    from q in query, prefix: ^Tenant.to_prefix(app), where: q.user_id == ^user.id
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
  def preload_user(query \\ __MODULE__) do
    from q in query, preload: [{:user, [:email]}]
  end

  @doc """
  Preload events.
  """
  def preload_events(query \\ __MODULE__) do
    from q in query, preload: [{:challenge, [:email_message]}, :events]
  end

  @doc """
  Preload associations.
  """
  def preload_challenge(query \\ __MODULE__) do
    from q in query,
      preload: [
        :rule,
        {:user, [:totps, :email, :emails, :phone, :phones]},
        {:challenge, [:email_message]},
        :events
      ]
  end

  @fields ~w(
    name
    data
    state
    rule_id
    user_id
  )a
  @required_fields @fields -- [:data]

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_data()
    |> validate_state()
    |> assoc_constraint(:user)
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

  defp validate_data(changeset) do
    changeset
    |> update_change(:data, fn
      data when is_map(data) ->
        (changeset.data.data || %{})
        |> Map.merge(data)
        |> Util.cast_property_map()

      data ->
        data
    end)
    |> ChangesetExt.validate_property_map(:data)
  end

  defp validate_state(changeset) do
    ChangesetExt.validate_state(changeset, pending: [:allow, :timeout, :block])
  end
end
