defmodule PasswordlessWeb.App.ActorLive.PropertiesComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Actor
  alias Passwordless.App

  @impl true
  def update(%{app: %App{} = app, actor: %Actor{} = actor} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(Passwordless.change_actor(app, actor))}
  end

  @impl true
  def handle_event("validate", %{"actor" => actor_params}, socket) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    changeset =
      app
      |> Passwordless.change_actor(actor, actor_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"actor" => actor_params}, socket) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.update_actor_properties(app, actor, actor_params) do
      {:ok, actor} ->
        changeset =
          app
          |> Passwordless.change_actor(actor)
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(actor: actor)
         |> assign_form(changeset)
         |> put_toast(:info, "User saved.", title: gettext("Success"))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
