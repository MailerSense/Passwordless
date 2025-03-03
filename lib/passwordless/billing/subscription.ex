defmodule Passwordless.Billing.Subscription do
  @moduledoc """
  Represents a subscription to a billing plan.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Passwordless.Billing.Customer
  alias Passwordless.Billing.SubscriptionItem
  alias Passwordless.Organizations.Org

  @stripe_states ~w(
    incomplete
    incomplete_expired
    trialing
    active
    past_due
    canceled
    unpaid
    expired
    paused
  )a
  @states @stripe_states

  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  schema "billing_subscriptions" do
    field :state, Ecto.Enum, values: @states
    field :provider_id, :string

    field :created_at, :utc_datetime_usec
    field :ended_at, :utc_datetime_usec
    field :cancel_at, :utc_datetime_usec
    field :canceled_at, :utc_datetime_usec
    field :current_period_start, :utc_datetime_usec
    field :current_period_end, :utc_datetime_usec
    field :trial_start, :utc_datetime_usec
    field :trial_end, :utc_datetime_usec

    belongs_to :customer, Customer

    has_many :items, SubscriptionItem

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Get subscription for an organization.
  """
  def get_by_org(%Org{} = org) do
    from s in __MODULE__, join: c in assoc(s, :customer), where: c.org_id == ^org.id
  end

  def valid?(%__MODULE__{} = subscription) do
    active?(subscription) or trial?(subscription) or grace_period?(subscription)
  end

  @doc """
  Returns whether the provided subscription is active, which is if it has not ended, and it has a valid status.
  """
  def active?(%__MODULE__{state: state} = subscription)
      when state not in ~w(incomplete incomplete_expired past_due unpaid)a,
      do: not ended?(subscription)

  def active?(%__MODULE__{}), do: false

  def trial?(%__MODULE__{state: :trialing, trial_end: %DateTime{} = trial_end}) do
    DateTime.after?(trial_end, DateTime.utc_now())
  end

  def trial?(%__MODULE__{}), do: false

  def grace_period?(%__MODULE__{state: :canceled, ended_at: %DateTime{} = ended_at}) do
    DateTime.after?(ended_at, DateTime.utc_now())
  end

  def grace_period?(%__MODULE__{}), do: false

  @doc """
  Returns whether the provided subscription has been cancelled and is no longer within its grace period.
  """
  def ended?(%__MODULE__{} = subscription) do
    canceled?(subscription) && !grace_period?(subscription)
  end

  @doc """
  Returns whether the provided subscription is recurring, which is the case if it has no end date and is not on a trial.
  """
  def recurring?(%__MODULE__{ended_at: ended_at} = subscription) do
    is_nil(ended_at) && !trial?(subscription)
  end

  @doc """
  Returns whether the provided subscription has been cancelled.
  """
  def canceled?(%__MODULE__{ended_at: %DateTime{}}), do: true
  def canceled?(%__MODULE__{}), do: false

  @fields ~w(
    state
    provider_id
    created_at
    ended_at
    cancel_at
    canceled_at
    current_period_start
    current_period_end
    trial_start
    trial_end
    customer_id
  )a
  @required_fields ~w(
    state
    provider_id
    customer_id
  )a

  @doc """
  A changeset to create a new billing subscription.
  """
  def changeset(%__MODULE__{} = subscription, attrs \\ %{}) do
    subscription
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:provider_id)
    |> unique_constraint(:customer_id)
    |> assoc_constraint(:customer)
  end
end
