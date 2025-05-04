defmodule PasswordlessWeb.App.BillingLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.Activity.Log

  @data_table_opts [
    for: Log,
    default_order: %{
      order_by: [:id],
      order_directions: [:desc]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign_stats()
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/billing")}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_logs, {:ok, %{logs: logs, meta: meta, cursor: cursor}}, socket) do
    socket = assign(socket, meta: meta, cursor: cursor, loading: false, finished: Enum.empty?(logs))
    socket = Enum.reduce(logs, socket, fn log, socket -> stream_insert(socket, :logs, log) end)

    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Billing"),
      page_subtitle: gettext("Manage your billing")
    )
  end

  defp assign_stats(socket) do
    users = Passwordless.get_app_user_count_cached(socket.assigns.current_app)
    mau = Passwordless.get_app_mau_count_cached(socket.assigns.current_app, Date.utc_today())
    apps = socket.assigns.current_org |> Passwordless.Organizations.list_apps() |> Enum.map(& &1.name)

    assign(socket, apps: apps, user_count: users, mau_count: mau)
  end
end
