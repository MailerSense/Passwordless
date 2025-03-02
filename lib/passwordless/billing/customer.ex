defmodule Passwordless.Billing.Customer do
  @moduledoc """
  A customer is something that has a subscription to a product.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Passwordless.Billing.Subscription
  alias Passwordless.Organizations.Org

  @providers ~w(stripe)a

  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  @schema_prefix "public"
  schema "billing_customers" do
    field :provider, Ecto.Enum, values: @providers
    field :provider_id, :string

    has_one :subscription, Subscription

    belongs_to :org, Org

    timestamps()
  end

  @doc """
  Get the customer for an organization.
  """
  def get_by_org(%Org{} = org) do
    from c in __MODULE__, where: c.org_id == ^org.id
  end

  @fields ~w(provider provider_id org_id)a
  @required_fields @fields

  @doc """
  A changeset to create a new billing customer.
  """
  def changeset(%__MODULE__{} = customer, attrs \\ %{}) do
    customer
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:org_id)
    |> unique_constraint(:provider_id)
    |> assoc_constraint(:org)
  end
end
