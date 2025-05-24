defmodule PasswordlessWeb.App.UserPoolLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.UserPool
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: UserPool,
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
  def handle_params(params, _url, socket) do
    user_pool =
      case Map.get(params, "id") do
        id when is_binary(id) -> Passwordless.get_user_pool!(socket.assigns.current_app, id)
        _ -> nil
      end

    {:noreply,
     socket
     |> assign(user_pool: user_pool, menu_items: user_menu_items())
     |> assign_user_pools(params)
     |> assign_filters(params)
     |> apply_action(socket.assigns.live_action, user_pool)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/user-pools")
     )}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/user-pools")
     )}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/user-pools")}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    filtered? =
      case Flop.validate(filter_params) do
        {:ok, %Flop{} = flop} -> Enum.any?(flop.filters, fn x -> x.value end)
        _ -> false
      end

    to =
      if filtered? do
        ~p"/user-pools?#{build_filter_params(socket.assigns.meta, filter_params)}"
      else
        ~p"/user-pools"
      end

    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("delete_user", %{"id" => id}, socket) do
    app = socket.assigns.current_app
    user = Passwordless.get_user!(app, id)

    case Passwordless.delete_user(app, user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User deleted successfully."))
         |> push_patch(to: ~p"/user-pools")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Failed to delete user!"), title: gettext("Error"))
         |> push_patch(to: ~p"/user-pools")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index, _) do
    assign(socket,
      page_title: gettext("User Pools"),
      page_subtitle: gettext("Manage your user pools")
    )
  end

  defp apply_action(socket, :new, _) do
    assign(socket,
      page_title: gettext("Create user pool"),
      page_subtitle:
        gettext(
          "Every person authenticating with your app will be recorded as a user. A Monthly Active User (MAU) is one that has performed at least two actions in the current month."
        )
    )
  end

  defp apply_action(socket, :edit, _) do
    assign(socket,
      page_title: gettext("Edit user pool"),
      page_subtitle:
        gettext(
          "Edit this user. You can view their enrolled authenticators and entire history, just scroll down a little."
        )
    )
  end

  defp apply_action(socket, :delete, %UserPool{} = user_pool) do
    assign(socket,
      page_title: gettext("Delete user pool"),
      page_subtitle:
        gettext(
          "Are you sure you want to delete user \"%{name}\"? This action is irreversible. User will lose access to their TOTPs and other authentication methods.",
          name: user_pool.name
        )
    )
  end

  defp apply_filters(filters, %Flop.Meta{} = meta, path)
       when is_map(filters) and map_size(filters) > 0 and is_binary(path) do
    path <> "?" <> Plug.Conn.Query.encode(DataTable.build_params(meta, filters))
  end

  defp apply_filters(_filters, _meta, path) when is_binary(path), do: path

  defp assign_filters(socket, params) do
    assign(socket, filters: Map.take(params, ~w(page filters order_by order_directions)))
  end

  defp assign_user_pools(socket, params) when is_map(params) do
    app = socket.assigns.current_app
    query = UserPool.get_by_app(app)

    {user_pools, meta} = DataTable.search(query, params, @data_table_opts)
    assign(socket, user_pools: user_pools, meta: meta)
  end
end
