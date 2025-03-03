defmodule PasswordlessWeb.App.ActorLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Actor
  alias Passwordless.App
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
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    actor = Passwordless.get_actor!(socket.assigns.current_app, id)

    {:noreply,
     socket
     |> assign(actor: actor, title_func: &title_func/1)
     |> assign_filters(params)
     |> assign_actors(params)
     |> apply_action(socket.assigns.live_action, actor)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(title_func: &title_func/1)
     |> assign_filters(params)
     |> assign_actors(params)
     |> apply_action(socket.assigns.live_action, nil)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/users")
     )}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/users")
     )}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/app/users")}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/app/users?#{DataTable.build_filter_params(socket.assigns.meta, filter_params)}"
     )}
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
         |> push_navigate(to: ~p"/app/users")}

      {:error, _} ->
        {:noreply,
         socket
         |> LiveToast.put_toast(:error, gettext("Failed to delete user!"))
         |> push_patch(to: ~p"/app/users")}
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
      page_subtitle: gettext("Import a user manually. You can also import users from a CSV file.")
    )
  end

  defp apply_action(socket, :edit, _) do
    assign(socket,
      page_title: gettext("Edit user"),
      page_subtitle: gettext("Manage your users")
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
          "Are you sure you want to delete user \"%{name}\"? This action is irreversible.",
          name: Actor.handle(actor)
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

  defp assign_actors(socket, params) when is_map(params) do
    query =
      case socket.assigns[:current_app] do
        %App{} = app ->
          app
          |> Actor.get_by_app()
          |> Actor.join_details(prefix: Database.Tenant.to_prefix(app))
          |> Actor.preload_details()

        _ ->
          Actor.get_none()
      end

    {actors, meta} = DataTable.search(query, params, @data_table_opts)
    assign(socket, actors: actors, meta: meta)
  end

  defp title_func(%Flop.Meta{flop: %Flop{filters: [_ | _] = filters}}) do
    Enum.find_value(
      filters,
      gettext("All users"),
      fn
        %Flop.Filter{field: :state, value: nil} -> gettext("All users")
        %Flop.Filter{field: :state, value: value} -> gettext("%{state} users", state: Phoenix.Naming.humanize(value))
        _ -> nil
      end
    )
  end

  defp title_func(_), do: gettext("All users")
end
