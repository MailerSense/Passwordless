defmodule PasswordlessWeb.App.ActorLive.IdentityComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Identity

  @impl true
  def update(%{app: %App{} = app, identity: %Identity{} = identity} = assigns, socket) do
    changeset = Passwordless.change_actor_identity(app, identity)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"identity" => email_params}, socket) do
    changeset =
      socket.assigns.app
      |> Passwordless.change_actor_identity(socket.assigns.identity, email_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"identity" => email_params}, socket) do
    save_email(socket, socket.assigns.live_action, email_params)
  end

  # Private

  defp save_email(socket, :edit, email_params) do
    app = socket.assigns.current_app
    identity = socket.assigns.identity

    case Passwordless.update_email(app, identity, email_params) do
      {:ok, _email} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("Identity has been updated."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_email(socket, :new, email_params) do
    case Passwordless.create_email(socket.assigns.current_app, email_params) do
      {:ok, _email} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("Identity has been created."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
