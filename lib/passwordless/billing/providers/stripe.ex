defmodule Passwordless.Billing.Providers.Stripe do
  @moduledoc """
  Stripe billing provider.
  """

  use Passwordless.Billing.Providers.Behaviour

  alias Passwordless.Billing
  alias Passwordless.Billing.Customer
  alias Passwordless.Billing.Subscription
  alias Passwordless.Organizations.Org
  alias Passwordless.Repo

  @impl true
  def checkout(%Org{} = org, plan \\ %{}) do
    with {:ok, customer} <- get_or_create_customer(org),
         {:ok, session} <- create_checkout_session(org, customer, plan),
         do: {:ok, customer, session}
  end

  @impl true
  def checkout_url(%Stripe.Checkout.Session{url: url}), do: url

  @impl true
  def change_plan(%Org{} = org, %Customer{subscription: %Subscription{} = subscription} = customer, items) do
    with {:ok, %Stripe.Subscription{} = stripe_subscription} <- Stripe.Subscription.retrieve(subscription.provider_id) do
      Stripe.BillingPortal.Session.create(%{
        customer: customer.provider_id,
        flow_data: %{
          type: :subscription_update_confirm,
          subscription_update_confirm: %{
            subscription: stripe_subscription.id,
            items: items
          },
          after_completion: %{
            type: :redirect,
            redirect: %{
              return_url: return_url(customer)
            }
          }
        }
      })
    end
  end

  @impl true
  def sync_subscription(%Stripe.Subscription{} = stripe_subscription) do
    case Billing.get_customer_by_provider_id(stripe_subscription.customer) do
      %Customer{} = customer ->
        subscription_attrs = parse_stripe_subscription(stripe_subscription)
        subscription_items_attrs = Enum.map(stripe_subscription.items, &parse_stripe_subscription_item/1)

        case Billing.get_subscription_by_provider_id(stripe_subscription.id) do
          %Subscription{} = subscription ->
            with {:ok, subscription} <- Billing.update_subscription(subscription, subscription_attrs),
                 do: Billing.reconcile_subscription_items(subscription, subscription_items_attrs)

          nil ->
            with {:ok, subscription} <- Billing.create_subscription(customer, subscription_attrs),
                 do: Billing.create_subscription_items(subscription, subscription_items_attrs)
        end

      nil ->
        {:error, :customer_not_found}
    end
  end

  @impl true
  def retrieve_subscription(subscription_id) do
    Stripe.Subscription.retrieve(subscription_id, %{expand: ["items.price"]})
  end

  @impl true
  def cancel_subscription(subscription_id) do
    Stripe.Subscription.cancel(subscription_id)
  end

  # Private

  defp get_or_create_customer(%Org{} = org) do
    case Repo.one(Customer.get_by_org(org)) do
      %Customer{} = customer ->
        {:ok, customer}

      nil ->
        customer_attrs =
          Util.maybe_put(%{name: org.name, metadata: %{"org_id" => org.id, "org_slug" => org.slug}}, :email, org.email)

        with {:ok, %Stripe.Customer{} = stripe_customer} <- Stripe.Customer.create(customer_attrs) do
          attrs = %{
            provider: :stripe,
            provider_id: stripe_customer.id
          }

          org
          |> Ecto.build_assoc(:billing_customer)
          |> Customer.changeset(attrs)
          |> Repo.insert()
        end
    end
  end

  defp create_checkout_session(%Org{} = org, %Customer{} = customer, plan) when is_map(plan) do
    data =
      case Map.get(plan, :trial_days) do
        trial_days when is_integer(trial_days) and trial_days > 0 ->
          %{
            trial_period_days: trial_days,
            metadata: %{
              "org_id" => org.id,
              "plan_id" => plan.id
            }
          }

        _ ->
          %{
            metadata: %{
              "org_id" => org.id,
              "plan_id" => plan.id
            }
          }
      end

    attrs = %{
      mode: :subscription,
      customer: customer.provider_id,
      line_items: plan.prices,
      client_reference_id: customer.id,
      success_url: success_url(customer),
      cancel_url: cancel_url(),
      subscription_data: data,
      allow_promotion_codes: plan.allow_promotion_codes
    }

    Stripe.Checkout.Session.create(attrs)
  end

  defp parse_stripe_subscription(%Stripe.Subscription{} = stripe_subscription) do
    attrs = %{
      state: stripe_subscription.status,
      provider_id: stripe_subscription.id
    }

    attrs
    |> Util.maybe_put(:created_at, Util.unix_to_datetime(stripe_subscription.created))
    |> Util.maybe_put(:ended_at, Util.unix_to_datetime(stripe_subscription.ended_at))
    |> Util.maybe_put(:cancel_at, cancel_at(stripe_subscription))
    |> Util.maybe_put(:canceled_at, canceled_at(stripe_subscription))
    |> Util.maybe_put(:current_period_start, Util.unix_to_datetime(stripe_subscription.current_period_start))
    |> Util.maybe_put(:current_period_end, Util.unix_to_datetime(stripe_subscription.current_period_end))
    |> Util.maybe_put(:trial_start, Util.unix_to_datetime(stripe_subscription.trial_start))
    |> Util.maybe_put(:trial_end, Util.unix_to_datetime(stripe_subscription.trial_end))
  end

  defp parse_stripe_subscription_item(%Stripe.SubscriptionItem{price: %Stripe.Price{} = price} = stripe_subscription_item) do
    attrs = %{
      name: price.nickname || price.id,
      provider_id: stripe_subscription_item.id,
      provider_price_id: price.id,
      provider_product_id: price.product
    }

    attrs
    |> Util.maybe_put(:quantity, stripe_subscription_item.quantity)
    |> Util.maybe_put(:created_at, Util.unix_to_datetime(stripe_subscription_item.created))
    |> Util.maybe_put(:recurring_interval, get_in(price.recurring, [:interval]))
    |> Util.maybe_put(:recurring_usage_type, get_in(price.recurring, [:usage_type]))
  end

  defp cancel_at(%Stripe.Subscription{cancel_at: cancel_at, cancel_at_period_end: cancel_at_period_end}) do
    if cancel_at_period_end do
      Util.unix_to_datetime(cancel_at_period_end)
    else
      Util.unix_to_datetime(cancel_at)
    end
  end

  defp canceled_at(%Stripe.Subscription{status: "canceled", cancel_at_period_end: cancel_at_period_end})
       when is_integer(cancel_at_period_end) and cancel_at_period_end > 0,
       do: Util.unix_to_datetime(cancel_at_period_end)

  defp canceled_at(%Stripe.Subscription{status: "canceled", cancel_at: cancel_at})
       when is_integer(cancel_at) and cancel_at > 0,
       do: Util.unix_to_datetime(cancel_at)

  defp canceled_at(%Stripe.Subscription{}), do: nil

  defp return_url(%Customer{} = customer) do
    success_url(customer) <> "&switch_plan=true"
  end
end
