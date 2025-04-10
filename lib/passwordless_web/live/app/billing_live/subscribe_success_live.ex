defmodule PasswordlessWeb.App.BillingLive.SubscribeSuccessLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Billing
  alias Passwordless.Billing.Subscription

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Subscribe Success"))
      |> assign(:source, socket.assigns.live_action)

    socket =
      case Billing.get_customer(socket.assigns.current_org) do
        %Billing.Customer{subscription: %Subscription{} = subscription} = customer ->
          socket
          |> assign(:current_customer, customer)
          |> assign(:current_subscription, subscription)

        _ ->
          socket
          |> assign(:current_customer, nil)
          |> assign(:current_subscription, nil)
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end
end
