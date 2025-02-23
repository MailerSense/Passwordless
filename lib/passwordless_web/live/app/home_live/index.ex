defmodule PasswordlessWeb.App.HomeLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Action
  alias Passwordless.Actor
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: Action,
    default_limit: 50,
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
     |> assign_actions(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/home")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/home")}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    if socket.assigns.finished do
      {:noreply, socket}
    else
      query =
        socket.assigns.current_project
        |> Action.get_by_project()
        |> Action.preload_actor()

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
  def handle_async(:load_actions, {:ok, %{actions: actions, meta: meta, cursor: cursor}}, socket) do
    socket = assign(socket, meta: meta, cursor: cursor, finished: Enum.empty?(actions))
    socket = stream(socket, :actions, actions)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: _event, payload: %Action{} = action}, socket) do
    {:noreply, stream_insert(socket, :actions, action, at: 0)}
  end

  @impl true
  def handle_info(_params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Home"),
      page_subtitle: gettext("Welcome to Passwordless")
    )
  end

  defp assign_actions(socket, params) do
    query =
      socket.assigns.current_project
      |> Action.get_by_project()
      |> Action.preload_actor()

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
end
