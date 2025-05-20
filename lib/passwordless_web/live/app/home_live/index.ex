defmodule PasswordlessWeb.App.HomeLive.Index do
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
  def handle_params(params, _url, socket) do
    app = socket.assigns.current_app

    if connected?(socket), do: Endpoint.subscribe(Action.topic_for(app))

    top_actions =
      app
      |> Passwordless.get_top_actions(limit: 3)
      |> Enum.map(fn %{
                       action: action,
                       attempts: total,
                       allows: allow,
                       timeouts: timeout,
                       blocks: block
                     } ->
        %{
          key: action,
          name: action,
          value: total,
          progress: %{
            max: total,
            items: [
              %{key: :allow, value: allow, color: "success"},
              %{key: :timeout, value: timeout, color: "warning"},
              %{key: :block, value: block, color: "danger"}
            ]
          }
        }
      end)

    authenticators =
      app
      |> Passwordless.list_authenticators()
      |> Enum.map(fn {key, authenticator} ->
        params =
          PasswordlessWeb.Helpers.authenticator_menu_items()
          |> Enum.find(&(&1[:name] == key))
          |> Map.take([:label, :icon, :path])

        Map.merge(%{id: key, enabled: authenticator.enabled}, params)
      end)

    {:noreply,
     socket
     |> assign(top_actions: top_actions, authenticators: authenticators)
     |> assign_events(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/home")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/home")}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    if socket.assigns[:finished] do
      {:noreply, socket}
    else
      query = event_query(socket.assigns.current_app)
      assigns = Map.take(socket.assigns, ~w(cursor)a)

      {:noreply,
       socket
       |> assign(finished: false)
       |> start_async(:load_events, fn -> load_events(query, assigns) end)}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: _event, payload: %Event{} = event}, socket) do
    socket = if(has_filters?(socket), do: socket, else: stream_insert(socket, :events, event, at: 0))
    socket = update_top_actions(socket, event)

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

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Home"),
      page_subtitle: gettext("Welcome to Passwordless")
    )
  end

  defp apply_action(socket, :view) do
    assign(socket,
      page_title: gettext("Action details"),
      page_subtitle: gettext("Review the action details and the events that led to it")
    )
  end

  defp assign_events(socket, params) do
    query = event_query(socket.assigns.current_app)
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

  defp event_query(%App{} = app) do
    app
    |> Event.get_by_app()
    |> Event.preload_user()
    |> Event.preload_action()
  end

  defp update_top_actions(socket, %Event{
         event: event_name,
         action: %Action{action_template: %ActionTemplate{name: action_name}, state: state}
       })
       when event_name in ~w(allow timeout block) do
    update(socket, :top_actions, fn top_actions ->
      Enum.map(top_actions, fn
        %{key: ^action_name, items: items, value: value} = top_action ->
          items =
            Enum.map(
              items,
              fn
                %{key: ^state, value: value} ->
                  %{key: state, value: value + 1}

                item ->
                  item
              end
            )

          %{top_action | value: value + 1, items: items}

        top_action ->
          top_action
      end)
    end)
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
