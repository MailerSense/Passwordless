defmodule PasswordlessWeb.App.UserLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Actor
  alias Passwordless.Project
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: Actor,
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
     |> assign_filters(params)
     |> assign_actors(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/users")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/users")}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/app/users")}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    flop =
      case Flop.validate(filter_params) do
        {:ok, %Flop{} = flop} -> flop
        _ -> nil
      end

    filtered? = flop && Enum.any?(flop.filters, fn x -> x.value end)

    socket = assign(socket, current_flop: flop)

    if filtered? do
      {:noreply,
       push_patch(socket,
         to: ~p"/app/users?#{DataTable.build_filter_params(socket.assigns.meta, filter_params)}"
       )}
    else
      {:noreply, push_patch(socket, to: ~p"/app/users")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Users"),
      page_subtitle: gettext("Manage your users")
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

  defp assign_actors(socket, params) when is_map(params) do
    case socket.assigns[:current_project] do
      %Project{} = project ->
        query =
          Actor.get_by_project(project)

        {actors, meta} = DataTable.search(query, params, @data_table_opts)
        assign(socket, actors: actors, meta: meta)

      _ ->
        {actors, meta} = DataTable.search(Actor.get_none(), params, @data_table_opts)
        assign(socket, actors: actors, meta: meta)
    end
  end
end
