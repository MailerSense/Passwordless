defmodule PasswordlessWeb.App.AppLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.App
  alias Passwordless.AppSettings
  alias Passwordless.Organizations.Org
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: App,
    default_order: %{
      order_by: [:inserted_at],
      order_directions: [:desc]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, url, socket) do
    app = Passwordless.get_app!(socket.assigns.current_org, id)
    socket = assign(socket, app: app)

    params
    |> Map.drop(["id"])
    |> handle_params(url, socket)
  end

  @impl true
  def handle_params(params, _url, socket) do
    current_org = socket.assigns.current_org

    new_app =
      current_org
      |> Ecto.build_assoc(:apps)
      |> Kernel.then(&%App{&1 | settings: %AppSettings{}})

    {:noreply,
     socket
     |> assign(new_app: new_app)
     |> assign_filters(params)
     |> assign_apps(params)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete_app", _params, socket) do
    case Passwordless.delete_app(socket.assigns.app) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("App deleted successfully."))
         |> push_navigate(to: ~p"/apps")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Failed to delete app!"), title: gettext("Error"))
         |> push_patch(to: ~p"/apps")}
    end
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/apps")
     )}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/apps")
     )}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/apps")}
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
      page_title: gettext("Create new app"),
      page_subtitle:
        gettext(
          "App is a container for your users, authentication methods and other data. Create one app per project or environment."
        )
    )
  end

  defp apply_action(socket, :edit, _params) do
    assign(socket,
      page_title: gettext("Edit app"),
      page_subtitle:
        gettext(
          "App is a container for your users, authentication methods and other data. Create one app per project or environment."
        )
    )
  end

  defp apply_action(socket, :delete, _params) do
    assign(socket,
      page_title: gettext("Are you sure?"),
      page_subtitle:
        gettext(
          "Are you sure you want to delete this app? All resources that belong to this app will be deleted as well - your users, authentication methods, etc. This action cannot be undone."
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

  defp assign_apps(socket, params) do
    case socket.assigns[:current_org] do
      %Org{} = org ->
        query = App |> App.get_by_org(org) |> App.preload_settings()
        {apps, meta} = DataTable.search(query, params, @data_table_opts)
        assign(socket, apps: apps, meta: meta)

      _ ->
        socket
    end
  end
end
