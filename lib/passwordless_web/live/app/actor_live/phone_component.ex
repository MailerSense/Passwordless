defmodule PasswordlessWeb.App.ActorLive.PhoneComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Phone

  @impl true
  def update(%{app: %App{} = app, phone: %Phone{} = phone} = assigns, socket) do
    changeset = Passwordless.change_actor_phone(app, phone)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"phone" => phone_params}, socket) do
    changeset =
      socket.assigns.app
      |> Passwordless.change_actor_phone(socket.assigns.phone, phone_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"phone" => phone_params}, socket) do
    save_phone(socket, socket.assigns.live_action, phone_params)
  end

  # Private

  defp save_phone(socket, :edit_phone, phone_params) do
    app = socket.assigns.current_app
    phone = socket.assigns.phone

    case Passwordless.update_actor_phone(app, phone, phone_params) do
      {:ok, _phone} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("Phone has been updated."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_phone(socket, :new_phone, phone_params) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.create_actor_phone(app, actor, phone_params) do
      {:ok, _phone} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("Phone has been created."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(phone_region: changeset |> Ecto.Changeset.get_field(:region) |> Util.trim_downcase())
  end
end
