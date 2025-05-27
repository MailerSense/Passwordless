defmodule PasswordlessWeb.App.UserPoolLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.UserPool

  @impl true
  def update(%{current_app: %App{} = app, user_pool: %UserPool{} = user_pool} = assigns, socket) do
    changeset = Passwordless.change_user_pool(app, user_pool)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user_pool" => user_pool_params}, socket) do
    app = socket.assigns.current_app
    user_pool = socket.assigns.user_pool

    changeset =
      app
      |> Passwordless.change_user_pool(user_pool, user_pool_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"user_pool" => user_pool_params}, socket) do
    save_user_pool(socket, user_pool_params)
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp save_user_pool(%{assigns: %{live_action: :new}} = socket, user_pool_params) do
    case Passwordless.create_user_pool(socket.assigns.current_app, user_pool_params) do
      {:ok, _user_pool} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("User pool created."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user_pool(%{assigns: %{live_action: :edit}} = socket, user_pool_params) do
    app = socket.assigns.current_app
    user_pool = socket.assigns.user_pool

    case Passwordless.update_user_pool(app, user_pool, user_pool_params) do
      {:ok, _user_pool} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("User pool updated."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
end
