defmodule PasswordlessWeb.Admin.ActivityLive.Index do
  @moduledoc """
  Allows for sending bulk emails to a list of recipients.
  """
  use PasswordlessWeb, :live_view

  alias Database.QueryExt
  alias Passwordless.Activity
  alias Passwordless.Activity.Log
  alias Passwordless.Repo
  alias PasswordlessWeb.Components.DataTable
  alias PasswordlessWeb.Endpoint

  @preloads [:org, :user]
  @data_table_opts [
    for: Log,
    default_limit: 30,
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
  def handle_event("load_more", _params, socket) do
    if socket.assigns.finished do
      {:noreply, socket}
    else
      query = QueryExt.preload(Log, @preloads)

      assigns = Map.take(socket.assigns, ~w(filters cursor)a)

      {:noreply,
       socket
       |> assign(loading: true, finished: false)
       |> start_async(:load_logs, fn -> load_logs(query, assigns) end)}
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, socket |> assign(current_flop: nil, last_flop: nil) |> push_patch(to: ~p"/admin/activity")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/admin/activity"))}
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
       push_patch(socket, to: ~p"/admin/activity?#{DataTable.build_filter_params(socket.assigns.meta, filter_params)}")}
    else
      {:noreply, push_patch(socket, to: ~p"/admin/activity")}
    end
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

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    log =
      id
      |> Activity.get!()
      |> Repo.preload(@preloads)

    {:noreply,
     socket
     |> assign(log: log)
     |> assign_filters(params)
     |> assign_logs(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    if connected?(socket), do: Endpoint.subscribe(Activity.topic_for(socket.assigns.current_org))

    socket =
      case {socket.assigns[:last_flop], socket.assigns[:current_flop]} do
        {nil, %Flop{} = flop} -> assign(socket, last_flop: flop, changed?: true)
        {%Flop{} = last_flop, %Flop{} = flop} -> assign(socket, last_flop: flop, changed?: last_flop != flop)
        _ -> assign(socket, last_flop: nil, changed?: true)
      end

    if socket.assigns[:changed?] do
      {:noreply,
       socket
       |> assign_filters(params)
       |> assign_logs(params)
       |> apply_action(socket.assigns.live_action)}
    else
      {:noreply, apply_action(socket, socket.assigns.live_action)}
    end
  end

  @impl true
  def handle_info(%{event: _event, payload: %Log{} = log}, socket) do
    {:noreply, if(has_filters?(socket), do: socket, else: stream_insert(socket, :logs, log, at: 0))}
  end

  @impl true
  def handle_info(_params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket, page_title: gettext("Events"))
  end

  defp apply_action(socket, :show) do
    assign(socket, page_title: gettext("Event"))
  end

  defp apply_filters(filters, %Flop.Meta{} = meta, path)
       when is_map(filters) and map_size(filters) > 0 and is_binary(path) do
    path <> "?" <> Plug.Conn.Query.encode(DataTable.build_params(meta, filters))
  end

  defp apply_filters(_filters, _meta, path) when is_binary(path), do: path

  defp assign_logs(socket, params) do
    query = QueryExt.preload(Log, @preloads)

    params = Map.take(params, ~w(filters order_by order_directions))

    {logs, meta} = DataTable.search(query, params, @data_table_opts)

    cursor =
      case List.last(logs) do
        %Log{} = log -> Flop.Cursor.encode(%{id: log.id})
        _ -> nil
      end

    socket
    |> assign(meta: meta, cursor: cursor, loading: false, finished: false)
    |> stream(:logs, logs, reset: true)
  end

  defp assign_filters(socket, params) do
    params = Map.take(params, ~w(filters order_by order_directions))

    flop =
      case Flop.validate(params) do
        {:ok, %Flop{} = flop} -> flop
        _ -> nil
      end

    assign(socket, filters: params, last_flop: flop)
  end

  defp has_filters?(socket) do
    case socket.assigns[:filters] do
      filters when is_map(filters) and map_size(filters) > 0 -> true
      _ -> false
    end
  end

  defp load_logs(query, %{filters: filters, cursor: cursor}) do
    filters = Map.merge(filters, %{"first" => 25, "after" => cursor})
    {logs, meta} = DataTable.search(query, filters, @data_table_opts)

    cursor =
      case List.last(logs) do
        %Log{} = log -> Flop.Cursor.encode(%{id: log.id})
        _ -> nil
      end

    %{logs: logs, meta: meta, cursor: cursor}
  end
end
