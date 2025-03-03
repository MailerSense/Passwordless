defmodule Passwordless.Billing.SubscriptionItem do
  @moduledoc """
  Represents a billable item belonging to a subscription.
  """

  use Passwordless.Schema

  alias Passwordless.Billing.Subscription

  @usage_types ~w(licensed metered)a
  @usage_intervals ~w(day month week year)a

  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  schema "billing_subscription_items" do
    field :name, :string
    field :quantity, :integer, default: 1

    field :created_at, :utc_datetime_usec
    field :provider_id, :string
    field :provider_price_id, :string
    field :provider_product_id, :string
    field :recurring_interval, Ecto.Enum, values: @usage_intervals
    field :recurring_usage_type, Ecto.Enum, values: @usage_types

    belongs_to :subscription, Subscription

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    name
    quantity
    created_at
    provider_id
    provider_price_id
    provider_product_id
    recurring_interval
    recurring_usage_type
    subscription_id
  )a
  @required_fields ~w(
    name
    quantity
    provider_id
    provider_price_id
    provider_product_id
    subscription_id
  )a

  @doc """
  A changeset to create a new billing subscription item.
  """
  def changeset(%__MODULE__{} = subscription_item, attrs \\ %{}) do
    subscription_item
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:provider_id)
    |> assoc_constraint(:subscription)
  end
end
