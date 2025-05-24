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
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
