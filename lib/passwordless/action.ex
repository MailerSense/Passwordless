defmodule Passwordless.Action do
  @moduledoc """
  An action.
  """

  use Passwordless.Schema, prefix: "action"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Database.Tenant
  alias Passwordless.ActionTemplate
  alias Passwordless.ActionToken
  alias Passwordless.App
  alias Passwordless.Challenge
  alias Passwordless.Event
  alias Passwordless.User

  @states ~w(allow timeout block pending)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :data,
      :state,
      :challenge,
      :events,
      :user,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "actions" do
    field :data, Passwordless.EncryptedMap
    field :state, Ecto.Enum, values: @states, default: :pending

    has_one :challenge, Challenge, where: [current: true]
    has_one :bearer_token, ActionToken, where: [kind: :bearer]
    has_one :exchange_token, ActionToken, where: [kind: :exchange]

    has_many :events, Event, preload_order: [asc: :inserted_at]
    has_many :challenges, Challenge, preload_order: [asc: :inserted_at]

    belongs_to :user, User
    belongs_to :action_template, ActionTemplate

    timestamps()
  end

  @doc """
  Returns a list of all possible action states.
  """
  def states, do: @states

  @doc """
  Returns a list of action states that are considered final (non-pending).
  """
  def final_states, do: @states -- [:pending]

  @doc """
  Generates a PubSub topic string for an app.
  """
  def topic_for(%App{} = app), do: "#{prefix()}:#{app.id}"

  @doc """
  Returns the standard preload associations for actions.
  """
  def preloads, do: [{:user, [:totps, :email, :emails, :phone, :phones]}, {:challenge, [:email_message]}, :events]

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
  end

  @doc """
  Get by action template.
  """
  def get_by_template(query \\ __MODULE__, %ActionTemplate{} = action_template) do
    from q in query, where: q.action_template_id == ^action_template.id
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
    from q in query, preload: [:user]
  end

  @doc """
  Preload events.
  """
  def preload_events(query \\ __MODULE__) do
    from q in query, preload: [:action_template, {:challenge, [:email_message]}, :events]
  end

  @doc """
  Preload associations.
  """
  def preload_challenge(query \\ __MODULE__) do
    from q in query,
      preload: [
        {:user, [:totps, :email, :emails, :phone, :phones]},
        {:challenge, [:email_message]},
        :events
      ]
  end

  @fields ~w(
    data
    state
    user_id
    action_template_id
  )a
  @required_fields @fields -- [:data]

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_data()
    |> validate_state()
    |> assoc_constraint(:user)
    |> assoc_constraint(:action_template)
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
