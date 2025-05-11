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
    for: Action,
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
    changeset = Passwordless.change_action_template(action_template)

    if connected?(socket), do: Endpoint.subscribe(Action.topic_for(current_app))

    {:noreply,
     socket
     |> assign(action_template: action_template)
     |> assign_action_form(changeset)
     |> assign_actions(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("validate", %{"action_template" => action_template_params}, socket) do
    changeset =
      socket.assigns.action_template
      |> Passwordless.change_action_template(action_template_params)
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
      query = user_query(socket.assigns.current_app, socket.assigns.action_template)
      assigns = Map.take(socket.assigns, ~w(cursor)a)

      {:noreply,
       socket
       |> assign(finished: false)
       |> start_async(:load_actions, fn -> load_actions(query, assigns) end)}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: _event, payload: %Action{} = action}, socket) do
    socket = if(has_filters?(socket), do: socket, else: stream_insert(socket, :actions, action, at: 0))

    {:noreply, socket}
  end

  @impl true
  def handle_info(_params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_actions, {:ok, %{actions: actions, meta: meta, cursor: cursor}}, socket) do
    socket = assign(socket, meta: meta, cursor: cursor, finished: Enum.empty?(actions))
    socket = stream(socket, :actions, actions)

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

  defp assign_actions(socket, params) do
    query = user_query(socket.assigns.current_app, socket.assigns.action_template)
    params = Map.take(params, ~w(filters order_by order_directions))
    {actions, meta} = DataTable.search(query, params, @data_table_opts)

    cursor =
      case List.last(actions) do
        %Action{} = action -> Flop.Cursor.encode(%{id: action.id})
        _ -> nil
      end

    socket
    |> assign(meta: meta, cursor: cursor, finished: false)
    |> stream(:actions, actions, reset: true)
  end

  defp load_actions(query, %{cursor: cursor}) do
    filters = %{"first" => 50, "after" => cursor}
    {actions, meta} = DataTable.search(query, filters, @data_table_opts)

    cursor =
      case List.last(actions) do
        %Action{} = action -> Flop.Cursor.encode(%{id: action.id})
        _ -> nil
      end

    %{actions: actions, meta: meta, cursor: cursor}
  end

  defp has_filters?(socket) do
    case socket.assigns[:filters] do
      filters when is_map(filters) and map_size(filters) > 0 -> true
      _ -> false
    end
  end

  defp user_query(%App{} = app, %ActionTemplate{} = action_template) do
    app
    |> Action.get_by_app()
    |> Action.get_by_template(action_template)
    |> Action.preload_user()
    |> Action.preload_events()
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
