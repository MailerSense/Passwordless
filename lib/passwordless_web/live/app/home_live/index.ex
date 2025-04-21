defmodule PasswordlessWeb.App.HomeLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Action
  alias Passwordless.App
  alias PasswordlessWeb.Components.DataTable
  alias PasswordlessWeb.Endpoint

  @data_table_opts [
    for: Action,
    count: 0,
    default_limit: 10,
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
      |> Passwordless.get_top_actions_cached()
      |> Enum.map(fn %{
                       total: total,
                       states: %{timeout: timeout, block: block, allow: allow},
                       action: action
                     } ->
        %{
          key: action,
          name: Phoenix.Naming.humanize(Macro.underscore(action)),
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
     |> assign_actions(params)
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
      query = actor_query(socket.assigns.current_app)

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
    socket =
      if(has_filters?(socket), do: socket, else: stream_insert(socket, :actions, action, at: 0))

    socket =
      socket
      |> update(:count, &(&1 + 1))
      |> update_top_actions(action)

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

  defp assign_actions(socket, params) do
    query = actor_query(socket.assigns.current_app)

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
    filters = %{"first" => 25, "after" => cursor}
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

  defp actor_query(%App{} = app) do
    app
    |> Action.get_by_app()
    |> Action.get_by_states([:allow, :timeout, :block])
    |> Action.preload_actor()
    |> Action.preload_challenge()
  end

  defp update_top_actions(socket, %Action{name: action_name, state: state}) do
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
end
