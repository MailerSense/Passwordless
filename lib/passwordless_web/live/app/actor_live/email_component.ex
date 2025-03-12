defmodule PasswordlessWeb.App.ActorLive.EmailComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Email

  @impl true
  def update(%{app: %App{} = app, email: %Email{} = email} = assigns, socket) do
    changeset = Passwordless.change_actor_email(app, email)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"email" => email_params}, socket) do
    changeset =
      socket.assigns.app
      |> Passwordless.change_actor_email(socket.assigns.email, email_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"email" => email_params}, socket) do
    save_email(socket, socket.assigns.live_action, email_params)
  end

  # Private

  defp save_email(socket, :edit_email, email_params) do
    app = socket.assigns.current_app
    email = socket.assigns.email

    case Passwordless.update_actor_email(app, email, email_params) do
      {:ok, _email} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("Email has been updated."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_email(socket, :new_email, email_params) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.create_actor_email(app, actor, email_params) do
      {:ok, _email} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("Email has been created."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
