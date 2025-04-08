defmodule Passwordless.Billing.Item do
  @moduledoc """
  The billing item schema.
  """

  use Passwordless.Schema, prefix: "blitem"

  alias Money.Ecto.Amount.Type, as: Cost
  alias Passwordless.App
  alias Passwordless.Organizations.Org

  @kinds ~w(metered)a
  @names ~w(
    mau_quota
    sms_quota
    email_quota
    whatsapp_quota
  )a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :kind,
      :name,
      :period_start,
      :period_end,
      :current,
      :amount,
      :amount_max,
      :base_cost,
      :added_cost,
      :total_cost,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  schema "billing_items" do
    field :kind, Ecto.Enum, values: @kinds
    field :name, Ecto.Enum, values: @names
    field :period_start, :utc_datetime_usec
    field :period_end, :utc_datetime_usec
    field :current, :boolean, virtual: true, default: false
    field :amount, :integer, default: 0
    field :amount_max, :integer, default: 0
    field :base_cost, Cost
    field :added_cost, Cost
    field :total_cost, Cost

    belongs_to :app, App
    belongs_to :org, Org

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    kind
    name
    period_start
    period_end
    current
    amount
    amount_max
    base_cost
    added_cost
    total_cost
    app_id
    org_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = billing_item, attrs \\ %{}) do
    billing_item
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_period()
    |> validate_amounts()
    |> validate_costs()
    |> assoc_constraint(:app)
    |> assoc_constraint(:org)
  end

  # Private

  defp validate_period(changeset) do
    case {get_field(changeset, :period_start), get_field(changeset, :period_end)} do
      {%DateTime{} = a, %DateTime{} = b} ->
        if DateTime.after?(a, b) do
          changeset
        else
          changeset
          |> add_error(:period_start, "must be before period start")
          |> add_error(:period_end, "must be after period end")
        end

      {%DateTime{}, _b} ->
        add_error(changeset, :period_end, "must be a valid date")

      {_a, %DateTime{}} ->
        add_error(changeset, :period_start, "must be a valid date")

      _ ->
        changeset
    end
  end

  defp validate_amounts(changeset) do
    changeset
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_number(:amount_max, greater_than_or_equal_to: 0)
  end

  defp validate_costs(changeset) do
    changeset
    |> validate_number(:base_cost, greater_than_or_equal_to: 0)
    |> validate_number(:added_cost, greater_than_or_equal_to: 0)
    |> validate_number(:total_cost, greater_than_or_equal_to: 0)
  end
end
