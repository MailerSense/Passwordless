defmodule Passwordless.Billing do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Passwordless.Activity
  alias Passwordless.App
  alias Passwordless.BillingCustomer
  alias Passwordless.BillingItem
  alias Passwordless.BillingSubscription
  alias Passwordless.BillingSubscriptionItem
  alias Passwordless.Organizations.Org
  alias Passwordless.Repo

  ## Customers

  def get_customer(%Org{} = org) do
    Customer |> Repo.get_by(org_id: org.id) |> Repo.preload(:subscription)
  end

  def get_customer_by_provider_id(provider_id) when is_binary(provider_id) do
    Customer |> Repo.get_by(provider_id: provider_id) |> Repo.preload(:subscription)
  end

  ## Billing Items

  def get_billing_item!(%Org{} = org, id) do
    org
    |> Ecto.assoc(:billing_items)
    |> Repo.get!(id)
    |> Repo.preload(:app)
    |> BillingItem.put_virtuals()
  end

  def create_billing_item(%Org{} = org, %App{} = app, attrs \\ %{}) do
    org
    |> Ecto.build_assoc(:billing_items)
    |> Kernel.then(&%BillingItem{&1 | app_id: app.id})
    |> BillingItem.changeset(attrs)
    |> Repo.insert()
  end

  def change_billing_item(%BillingItem{} = billing_item, attrs \\ %{}) do
    BillingItem.changeset(billing_item, attrs)
  end

  ## Plan

  def get_current_plan(%Org{} = _org) do
    {:paid, :business, 5}
  end

  ## Subscriptions

  def get_subscription(id) when is_binary(id) do
    BillingSubscription |> Repo.get(id) |> Repo.preload(:items)
  end

  def get_subscription_by_org(%Org{} = org) do
    org |> BillingSubscription.get_by_org() |> Repo.preload([{:customer, [:org]}, :items])
  end

  def get_subscription_by_customer_id(customer_id) when is_binary(customer_id) do
    BillingSubscription |> Repo.get_by(customer_id: customer_id) |> Repo.preload([{:customer, [:org]}, :items])
  end

  def get_subscription_by_provider_id(provider_id) when is_binary(provider_id) do
    BillingSubscription |> Repo.get_by(provider_id: provider_id) |> Repo.preload([{:customer, [:org]}, :items])
  end

  def create_subscription(%BillingCustomer{} = customer, attrs \\ %{}) do
    customer
    |> Ecto.build_assoc(:subscription)
    |> BillingSubscription.changeset(attrs)
    |> Repo.insert()
  end

  def create_subscription_items(%BillingSubscription{} = subscription, items_attrs \\ []) do
    results =
      Enum.map(items_attrs, fn item_attrs ->
        subscription
        |> Ecto.build_assoc(:subscription_items)
        |> BillingSubscriptionItem.changeset(item_attrs)
        |> Repo.insert()
      end)

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:ok,
       %BillingSubscription{subscription | items: Enum.map(results, fn {:ok, %BillingSubscriptionItem{} = i} -> i end)}}
    else
      {:error, :subscription_item_insert_failed}
    end
  end

  def reconcile_subscription_items(%BillingSubscription{} = subscription, subscription_items_attrs) do
    old_items = Map.new(subscription.items, fn i -> {i.provider_id, {:old, i}} end)
    new_items = Map.new(subscription_items_attrs, fn i -> {i.provider_id, {:new, i}} end)
    diffs = Map.merge(old_items, new_items, fn _id, {:old, old}, {:new, new} -> {:changed, old, new} end)

    results =
      diffs
      |> Map.values()
      |> Enum.map(fn
        {:new, new} -> {:insert, BillingSubscriptionItem.changeset(%BillingSubscriptionItem{}, new)}
        {:old, old} -> {:delete, old}
        {:changed, old, new} -> {:update, BillingSubscriptionItem.changeset(old, new)}
      end)
      |> Enum.map(fn
        {:insert, changeset} -> {:insert, Repo.insert(changeset)}
        {:update, changeset} -> {:update, Repo.update(changeset)}
        {:delete, item} -> {:delete, Repo.soft_delete(item)}
      end)
      |> Enum.map(fn
        {action, {:ok, item}} ->
          with {:ok, _log} <- log_subscription_item_action(action, subscription, item),
               do: {:ok, item}

        {_action, {:error, changeset}} ->
          {:error, changeset}
      end)

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:ok, Repo.preload(subscription, :items)}
    else
      {:error, :subscription_item_reconciliation_failed}
    end
  end

  def update_subscription(%BillingSubscription{} = subscription, attrs \\ %{}) do
    subscription
    |> BillingSubscription.changeset(attrs)
    |> Repo.update()
  end

  def cancel_subscription(%BillingSubscription{} = subscription) do
    update_subscription(subscription, %{
      status: :canceled,
      canceled_at: DateTime.utc_now()
    })
  end

  def delete_subscription(%BillingSubscription{} = subscription) do
    Repo.transact(fn ->
      with {:ok, subscription} <- Repo.soft_delete(subscription),
           true <- Enum.all?(Enum.map(subscription.items, &Repo.soft_delete/1), &match?({:ok, _}, &1)),
           do: {:ok, subscription}
    end)
  end

  def has_valid_subscription?(%Org{} = org) do
    case Repo.one(BillingSubscription.get_by_org(org)) do
      %BillingSubscription{} = subscription -> BillingSubscription.valid?(subscription)
      _ -> false
    end
  end

  # Private

  defp log_subscription_item_action(action, %BillingSubscription{} = subscription, %BillingSubscriptionItem{} = item) do
    log_action =
      case action do
        :insert -> :"subscription_item.created"
        :update -> :"subscription_item.updated"
        :delete -> :"subscription_item.deleted"
      end

    log_params =
      item
      |> Map.from_struct()
      |> Map.take(BillingSubscriptionItem.__schema__(:fields))
      |> Map.put(:billing_subscription, subscription)

    Activity.log(log_action, log_params)
  end
end
