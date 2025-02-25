defmodule PasswordlessWeb.App.AppLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.App
  alias Passwordless.Organizations.Org
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: App,
    default_order: %{
      order_by: [:id],
      order_directions: [:desc]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    app = Passwordless.get_app!(socket.assigns.current_org, id)

    {:noreply,
     socket
     |> assign(app: app)
     |> assign_filters(params)
     |> assign_apps(params)
     |> assign_form(Passwordless.change_app(app))
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign_filters(params)
     |> assign_apps(params)}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    query_params = DataTable.build_filter_params(socket.assigns.meta, filter_params)
    {:noreply, push_patch(socket, to: ~p"/app/apps?#{query_params}")}
  end

  @impl true
  def handle_event("delete_app", %{"id" => id}, socket) do
    app = Passwordless.get_app(socket.assigns.current_org, id)

    case socket.assigns[:current_app] do
      %App{id: ^id} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("You cannot delete the project you are currently viewing."))
         |> push_patch(to: ~p"/app/apps")}

      _ ->
        case Passwordless.delete_app(app) do
          {:ok, _app} ->
            {:noreply,
             socket
             |> put_flash(:info, gettext("App deleted successfully."))
             |> push_navigate(to: ~p"/app/apps")}

          {:error, _} ->
            {:noreply,
             socket
             |> LiveToast.put_toast(:error, gettext("Failed to delete project!"))
             |> push_patch(to: ~p"/app/apps")}
        end
    end
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/apps")
     )}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/apps")
     )}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index, _params) do
    assign(socket,
      page_title: gettext("Apps")
    )
  end

  defp apply_action(socket, :new, _params) do
    assign(socket,
      page_title: gettext("Create app")
    )
  end

  defp apply_action(socket, :edit, _params) do
    assign(socket,
      page_title: gettext("Edit app")
    )
  end

  defp apply_action(socket, :delete, _params) do
    assign(socket,
      page_title: gettext("Are you sure?"),
      page_subtitle: gettext("Are you sure you want to delete this app?")
    )
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp apply_filters(filters, %Flop.Meta{} = meta, path)
       when is_map(filters) and map_size(filters) > 0 and is_binary(path) do
    path <> "?" <> Plug.Conn.Query.encode(update_filter_params(meta, filters))
  end

  defp apply_filters(_filters, _meta, path) when is_binary(path), do: path

  defp assign_filters(socket, params) do
    assign(socket, filters: Map.take(params, ~w(page filters order_by order_directions)))
  end

  defp assign_apps(socket, params) do
    case socket.assigns[:current_org] do
      %Org{} = org ->
        query = App.get_by_org(org)
        {apps, meta} = DataTable.search(query, params, @data_table_opts)
        assign(socket, apps: apps, meta: meta)

      _ ->
        socket
    end
  end

  defp is_current_app?(%App{id: id}, %App{id: id}) when is_binary(id), do: true
  defp is_current_app?(%App{}, _), do: false
end
