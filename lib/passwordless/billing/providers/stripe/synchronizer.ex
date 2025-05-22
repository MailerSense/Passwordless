defmodule Passwordless.Billing.Providers.Stripe.Synchronizer do
  @moduledoc """
  Synchronizes Stripe subscriptions with Passwordless subscriptions.
  """

  use Oban.Pro.Worker, queue: :stripe, max_attempts: 5, tags: ["synchronizer", "stripe"]

  alias Passwordless.Activity
  alias Passwordless.Billing
  alias Passwordless.Billing.Providers.Stripe, as: StripeProvider
  alias Passwordless.BillingSubscription
  alias Passwordless.Repo

  @event_mapping %{
    "customer.subscription.created" => :"subscription.created",
    "customer.subscription.updated" => :"subscription.updated",
    "customer.subscription.deleted" => :"subscription.deleted",
    "customer.subscription.paused" => :"subscription.paused",
    "customer.subscription.resumed" => :"subscription.resumed",
    "customer.subscription.trial_will_end" => :"subscription.trial_will_be_ended"
  }

  @impl true
  def process(%Oban.Job{args: %{"provider_subscription_id" => provider_subscription_id, "event_type" => event_type}}) do
    log_type = Map.get(@event_mapping, event_type, :"subscription.updated")

    with {:ok, %Stripe.Subscription{} = stripe_subscription} <-
           StripeProvider.retrieve_subscription(provider_subscription_id) do
      Repo.transact(fn ->
        with {:ok, subscription} <- StripeProvider.sync_subscription(stripe_subscription),
             {:ok, subscription} <- maybe_delete_subscription(log_type, subscription),
             {:ok, _log} <- Activity.log(log_type, %{billing_subscription: subscription}),
             do: {:ok, subscription}
      end)
    end
  end

  # Private

  defp maybe_delete_subscription(:"subscription.deleted", %BillingSubscription{} = subscription) do
    Billing.delete_subscription(subscription)
  end

  defp maybe_delete_subscription(_event_type, subscription), do: {:ok, subscription}
end
