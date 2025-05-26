defmodule PasswordlessWeb.App.ActionLive.Activity do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Action
  alias Passwordless.ActionTemplate
  alias Passwordless.App
  alias Passwordless.Event
  alias PasswordlessWeb.Components.DataTable
  alias PasswordlessWeb.Endpoint

  @data_table_opts [
    for: Event,
    count: 0,
    default_limit: 25,
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
  def handle_params(%{"id" => id} = params, _url, %{assigns: %{current_app: %App{} = current_app}} = socket) do
    action_template = Passwordless.get_action_template!(current_app, id)
    changeset = Passwordless.change_action_template(current_app, action_template)

    stats = Passwordless.get_action_performance_stats(current_app, action_template)

    IO.inspect(stats, label: "Action Template Stats")

    all_attempts =
      current_app
      |> Passwordless.get_top_actions()
      |> Enum.map(& &1.attempts)
      |> Enum.sum()

    unique_users = Passwordless.get_action_template_unique_users(current_app, action_template)
    all_users = Passwordless.get_total_users(current_app)

    if connected?(socket), do: Endpoint.subscribe(Action.topic_for(current_app))

    {:noreply,
     socket
     |> assign(
       action_template: action_template,
       all_attempts: all_attempts,
       unique_users: unique_users,
       all_users: all_users,
       stats: stats
     )
     |> assign_action_form(changeset)
     |> assign_events(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("validate", %{"action_template" => action_template_params}, socket) do
    changeset =
      socket.assigns.current_app
      |> Passwordless.change_action_template(socket.assigns.action_template, action_template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_action_form(socket, changeset)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/actions/#{socket.assigns.action_template}/activity")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/actions/#{socket.assigns.action_template}/activity")}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    if socket.assigns[:finished] do
      {:noreply, socket}
    else
      query = event_query(socket.assigns.current_app, socket.assigns.action_template)
      assigns = Map.take(socket.assigns, ~w(cursor)a)

      {:noreply,
       socket
       |> assign(finished: false)
       |> start_async(:load_events, fn -> load_events(query, assigns) end)}
    end
  end

  @impl true
  def handle_event("delete_action_template", _params, socket) do
    action_template = socket.assigns.action_template

    case Passwordless.delete_action_template(action_template) do
      {:ok, _action_template} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("Action has been deleted."), title: gettext("Success"))
         |> push_navigate(to: ~p"/actions")}

      _ ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Failed to delete action!"), title: gettext("Error"))
         |> push_patch(to: ~p"/actions")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: _event, payload: %Event{} = event}, socket) do
    socket = if(has_filters?(socket), do: socket, else: stream_insert(socket, :events, event, at: 0))
    {:noreply, socket}
  end

  @impl true
  def handle_info(_params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_events, {:ok, %{events: events, meta: meta, cursor: cursor}}, socket) do
    socket = assign(socket, meta: meta, cursor: cursor, finished: Enum.empty?(events))
    socket = stream(socket, :events, events)

    {:noreply, socket}
  end

  @impl true
  def handle_async(_event, _reply, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :delete) do
    assign(socket,
      page_title: gettext("Delete action"),
      page_subtitle:
        gettext(
          "Are you sure you want to delete this action? This action will be permanently deleted, and all widgets or API integrations using this action will stop working."
        )
    )
  end

  defp apply_action(socket, _action) do
    assign(socket,
      page_title: gettext("Action Activity"),
      page_subtitle: gettext("Manage this action")
    )
  end

  defp assign_action_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, action_form: to_form(changeset))
  end

  defp assign_events(socket, params) do
    query = event_query(socket.assigns.current_app, socket.assigns.action_template)
    params = Map.take(params, ~w(filters order_by order_directions))
    {events, meta} = DataTable.search(query, params, @data_table_opts)

    cursor =
      case List.last(events) do
        %Event{} = event -> Flop.Cursor.encode(%{id: event.id})
        _ -> nil
      end

    socket
    |> assign(meta: meta, cursor: cursor, finished: false)
    |> stream(:events, events, reset: true)
  end

  defp load_events(query, %{cursor: cursor}) do
    filters = %{"first" => 50, "after" => cursor}
    {events, meta} = DataTable.search(query, filters, @data_table_opts)

    cursor =
      case List.last(events) do
        %Event{} = event -> Flop.Cursor.encode(%{id: event.id})
        _ -> nil
      end

    %{events: events, meta: meta, cursor: cursor}
  end

  defp has_filters?(socket) do
    case socket.assigns[:filters] do
      filters when is_map(filters) and map_size(filters) > 0 -> true
      _ -> false
    end
  end

  defp event_query(%App{} = app, %ActionTemplate{} = action_template) do
    app
    |> Event.get_by_app()
    |> Event.preload_user()
    |> Event.preload_action()
    |> Event.get_by_template(app, action_template)
  end

  defp browser_to_icon("Microsoft Edge"), do: "edge"
  defp browser_to_icon(browser), do: String.downcase(browser)

  defp os_to_icon("Mac"), do: "macos"
  defp os_to_icon("Windows"), do: "windows"
  defp os_to_icon("Linux"), do: "linux"
  defp os_to_icon("Android"), do: "android"
  defp os_to_icon("iOS"), do: "ios"
  defp os_to_icon("Chrome OS"), do: "chromeos"
  defp os_to_icon(os), do: String.downcase(os)

  defp device_type_to_icon("desktop"), do: "remix-computer-line"
  defp device_type_to_icon("mobile"), do: "remix-smartphone-line"
  defp device_type_to_icon(_), do: "remix-tablet-line"
end
