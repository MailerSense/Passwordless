defmodule Passwordless.Billing.Providers.Stripe.WebhookHandler do
  @moduledoc """
  A plug in endpoint.ex forwards Stripe webhooks to here (Stripe.WebhookPlug)
  """

  @behaviour Stripe.WebhookHandler

  alias Passwordless.Activity
  alias Passwordless.Billing
  alias Passwordless.Billing.Providers.Stripe.Synchronizer
  alias Passwordless.Billing.Subscription
  alias Passwordless.Repo

  @doc """
  Handle Stripe events here.

  This event is called when a subscription is created, updated, canceled.
  This could have happened from a user/org in a Stripe-hosted portal or by a site admin from the Stripe dashboard.

  Created is triggered for trial subscription only.
  Both Created and Updated are triggered for all other subscriptions.

  This means for a non-trial subscription, sync will be called twice, but given
  how sync works, the second call has no side effect.

  List of all Stripe events: https://stripe.com/docs/api/events/types
  """
  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.created" = type, data: %{object: object}}) do
    schedule_synchronization(object.id, type)
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.updated" = type, data: %{object: object}}) do
    schedule_synchronization(object.id, type)
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.deleted" = type, data: %{object: object}}) do
    schedule_synchronization(object.id, type)
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.paused" = type, data: %{object: object}}) do
    schedule_synchronization(object.id, type)
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.resumed" = type, data: %{object: object}}) do
    schedule_synchronization(object.id, type)
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.trial_will_end" = type, data: %{object: object}}) do
    schedule_synchronization(object.id, type)
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription." <> _rest = type, data: %{object: object}}) do
    payload = %{stripe_subscription_event: type}

    Repo.transact(fn ->
      with %Subscription{} = subscription <- Billing.get_subscription_by_provider_id(object.id),
           {:ok, _log} <-
             Activity.log(:billing, :"subscription.updated", Map.put(payload, :billing_subscription, subscription)),
           do: {:ok, subscription}
    end)
  end

  @impl true
  def handle_event(_), do: :ok

  # Private

  defp schedule_synchronization(provider_subscription_id, type) do
    %{provider_subscription_id: provider_subscription_id, event_type: type}
    |> Synchronizer.new()
    |> Oban.insert()
  end
end
