defmodule PasswordlessWeb.App.ActorLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Actor
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: Actor,
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
    actor =
      case Map.get(params, "id") do
        id when is_binary(id) -> Passwordless.get_actor!(socket.assigns.current_app, id)
        _ -> nil
      end

    {:noreply,
     socket
     |> assign(actor: actor)
     |> assign_filters(params)
     |> assign_actors(params)
     |> assign_stats()
     |> apply_action(socket.assigns.live_action, actor)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    IO.inspect("here2")
    IO.inspect(socket.assigns.filters, label: "filters")
    IO.inspect(socket.assigns.meta, label: "meta")

    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/users")
     )}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    IO.inspect("here")
    IO.inspect(socket.assigns.filters, label: "filters")
    IO.inspect(socket.assigns.meta, label: "meta")

    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/users")
     )}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/users")}
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
        ~p"/users?#{build_filter_params(socket.assigns.meta, filter_params)}"
      else
        ~p"/users"
      end

    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("delete_actor", %{"id" => id}, socket) do
    app = socket.assigns.current_app
    actor = Passwordless.get_actor!(app, id)

    case Passwordless.delete_actor(app, actor) do
      {:ok, _actor} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User deleted successfully."))
         |> push_patch(to: ~p"/users")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Failed to delete user!"), title: gettext("Error"))
         |> push_patch(to: ~p"/users")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index, _) do
    assign(socket,
      page_title: gettext("Users"),
      page_subtitle: gettext("Manage your users")
    )
  end

  defp apply_action(socket, :new, _) do
    assign(socket,
      page_title: gettext("Create user"),
      page_subtitle: gettext("Create a new app user. You can also import users in batch from a CSV file.")
    )
  end

  defp apply_action(socket, :edit, _) do
    assign(socket,
      page_title: gettext("Edit user"),
      page_subtitle:
        gettext(
          "Edit this user. You can view their enrolled authenticators and entire history, just scroll down a little."
        )
    )
  end

  defp apply_action(socket, :import, _) do
    assign(socket,
      page_title: gettext("Import users"),
      page_subtitle:
        gettext(
          "Import existing users from a CSV file. Download our reference CSV template and fill it out with your users."
        )
    )
  end

  defp apply_action(socket, :delete, %Actor{} = actor) do
    assign(socket,
      page_title: gettext("Delete user"),
      page_subtitle:
        gettext(
          "Are you sure you want to delete user \"%{name}\"? This action is irreversible. User will lose access to their TOTPs and other authentication methods.",
          name: Actor.handle(actor)
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

  defp assign_actors(socket, params) when is_map(params) do
    app = socket.assigns.current_app

    query =
      app
      |> Actor.get_by_app()
      |> Actor.join_details(prefix: Database.Tenant.to_prefix(app))
      |> Actor.preload_details()

    {actors, meta} = DataTable.search(query, params, @data_table_opts)
    assign(socket, actors: actors, meta: meta)
  end

  defp assign_stats(socket) do
    users = Passwordless.get_app_user_count_cached(socket.assigns.current_app)
    mau = Passwordless.get_app_mau_count_cached(socket.assigns.current_app, Date.utc_today())

    assign(socket, user_count: users, mau_count: mau)
  end
end
