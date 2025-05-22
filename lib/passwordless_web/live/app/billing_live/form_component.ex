defmodule PasswordlessWeb.App.BillingLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.BillingItem

  @impl true
  def update(%{billing_item: %BillingItem{} = billing_item} = assigns, socket) do
    changeset = Passwordless.Billing.change_billing_item(billing_item)
    {:ok, socket |> assign(assigns) |> assign_form(changeset)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
