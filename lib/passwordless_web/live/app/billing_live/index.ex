defmodule PasswordlessWeb.App.BillingLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.BillingItem
  alias Passwordless.Locale.Number, as: NumberLocale
  alias Passwordless.Organizations.Org
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: BillingItem,
    default_order: %{
      order_by: [:name],
      order_directions: [:desc]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, url, %{assigns: %{live_action: :edit_billing_item}} = socket) do
    billing_item = Passwordless.Billing.get_billing_item!(socket.assigns.current_org, id)
    socket = assign(socket, billing_item: billing_item)

    params
    |> Map.drop(["id"])
    |> handle_params(url, socket)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign_filters(params)
     |> assign_stats()
     |> assign_billing_items(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/billing")
     )}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/billing")
     )}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/billing")}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Billing"),
      page_subtitle: gettext("Manage your billing")
    )
  end

  defp apply_action(socket, :edit_billing_item) do
    assign(socket,
      page_title: gettext("Billing item"),
      page_subtitle:
        gettext(
          "This is a part of your invoice for the selected billing period. The charge is not final until the invoice is created."
        )
    )
  end

  defp apply_filters(filters, %Flop.Meta{} = meta, path)
       when is_map(filters) and map_size(filters) > 0 and is_binary(path) do
    path <> "?" <> Plug.Conn.Query.encode(update_filter_params(meta, filters))
  end

  defp apply_filters(_filters, _meta, path) when is_binary(path), do: path

  defp assign_filters(socket, params) do
    assign(socket, filters: Map.take(params, ~w(page filters order_by order_directions)))
  end

  defp assign_billing_items(socket, params) do
    case socket.assigns[:current_org] do
      %Org{} = org ->
        query = BillingItem |> BillingItem.get_by_org(org) |> BillingItem.preload_app()
        {billing_items, meta} = DataTable.search(query, params, @data_table_opts)
        billing_items = Enum.map(billing_items, &BillingItem.put_virtuals/1)
        assign(socket, billing_items: billing_items, meta: meta)

      _ ->
        socket
    end
  end

  defp assign_stats(socket) do
    users = Passwordless.get_app_user_count_cached(socket.assigns.current_app)
    mau = Passwordless.get_app_mau_count_cached(socket.assigns.current_app, Date.utc_today())
    apps = socket.assigns.current_org |> Passwordless.Organizations.list_apps() |> Enum.map(& &1.name)

    assign(socket, apps: apps, user_count: users, mau_count: mau)
  end
end
