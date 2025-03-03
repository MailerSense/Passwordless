defmodule PasswordlessWeb.App.ActorLive.Activity do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Action
  alias Passwordless.Actor
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: Action,
    default_limit: 30,
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
    changeset = Passwordless.change_actor(actor)

    {:noreply,
     socket
     |> assign(actor: actor)
     |> assign_form(changeset)
     |> assign_actions(actor, params)
     |> apply_action(socket.assigns.live_action, actor)}
  end

  @impl true
  def handle_event("save", %{"actor" => actor_params}, socket) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.update_actor(app, actor, actor_params) do
      {:ok, actor} ->
        changeset =
          actor
          |> Passwordless.change_actor()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(actor: actor)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"actor" => actor_params}, socket) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.update_actor(app, actor, actor_params) do
      {:ok, actor} ->
        changeset =
          actor
          |> Passwordless.change_actor()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(actor: actor)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("delete_actor", _params, socket) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

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
         |> push_patch(to: ~p"/app/users/#{actor}/activity")}
    end
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    if socket.assigns.finished do
      {:noreply, socket}
    else
      query =
        socket.assigns.current_app
        |> Action.get_by_app()
        |> Action.get_by_actor(socket.assigns.actor)

      assigns = Map.take(socket.assigns, ~w(cursor)a)

      {:noreply,
       socket
       |> assign(finished: false)
       |> start_async(:load_actions, fn -> load_actions(query, assigns) end)}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/users/#{socket.assigns.actor}/activity")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/users/#{socket.assigns.actor}/activity")}
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp apply_action(socket, :edit, %Actor{} = actor) do
    assign(socket, page_title: Actor.handle(actor))
  end

  defp apply_action(socket, :delete, _actor) do
    assign(socket,
      page_title: gettext("Are you sure?"),
      page_subtitle: gettext("Are you sure you want to delete this actor? This action cannot be undone.")
    )
  end

  defp assign_actions(socket, actor, params) do
    query =
      socket.assigns.current_app
      |> Action.get_by_app()
      |> Action.get_by_actor(actor)

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
    filters = %{"first" => 30, "after" => cursor}
    {actions, meta} = DataTable.search(query, filters, @data_table_opts)

    cursor =
      case List.last(actions) do
        %Action{} = action -> Flop.Cursor.encode(%{id: action.id})
        _ -> nil
      end

    %{actions: actions, meta: meta, cursor: cursor}
  end
end
