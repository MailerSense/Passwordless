defmodule Passwordless.Challenge do
  @moduledoc """
  An actor avent.
  """

  use Passwordless.Schema

  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.App

  @size 32
  @states ~w(initiated verified failed timed_out)a
  @contexts [
    session: :timer.hours(7 * 24),
    email_change: :timer.hours(6),
    email_confirmation: :timer.hours(6),
    password_reset: :timer.hours(6),
    passwordless_sign_in: :timer.minutes(30)
  ]
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "challenges" do
    field :state, Ecto.Enum, values: @states
    field :method, Ecto.Enum, values: Passwordless.methods()
    field :context, Ecto.Enum, values: Keyword.keys(@contexts)
    field :expires_at, :utc_datetime_usec
    field :attempts, :integer, default: 0
    field :token, :binary

    belongs_to :app, App, type: :binary_id
    belongs_to :actor, Actor, type: :binary_id
    belongs_to :action, Action, type: :binary_id

    timestamps()
  end

  @fields ~w(
    state
    method
    context
    expires_at
    attempts
    token
    app_id
    actor_id
    action_id
  )a
  @required_fields @fields -- ~w(action_id)a

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_number(:attempts, greater_than_or_equal_to: 0)
    |> unique_constraint([:app_id, :token], error_key: :token)
    |> unique_constraint([:app_id, :actor_id, :token], error_key: :token)
    |> unique_constraint([:app_id, :actor_id, :action_id], error_key: :action_id)
    |> unsafe_validate_unique([:app_id, :token], Passwordless.Repo, error_key: :token)
    |> unsafe_validate_unique([:app_id, :actor_id, :token], Passwordless.Repo, error_key: :token)
    |> unsafe_validate_unique([:app_id, :actor_id, :action_id], Passwordless.Repo, error_key: :action_id)
    |> assoc_constraint(:app)
    |> assoc_constraint(:actor)
    |> assoc_constraint(:action)
  end
end
