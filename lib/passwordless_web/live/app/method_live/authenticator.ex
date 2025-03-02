defmodule PasswordlessWeb.App.MethodLive.Authenticator do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    authenticator = Repo.preload(app, :authenticator).authenticator
    changeset = Passwordless.change_authenticator(authenticator)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(authenticator: authenticator)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"authenticator" => authenticator_params}, socket) do
    save_authenticator(socket, authenticator_params)
  end

  @impl true
  def handle_event("validate", %{"authenticator" => authenticator_params}, socket) do
    save_authenticator(socket, authenticator_params)
  end

  # Private

  defp save_authenticator(socket, params) do
    case Passwordless.update_authenticator(socket.assigns.authenticator, params) do
      {:ok, authenticator} ->
        changeset =
          authenticator
          |> Passwordless.change_authenticator()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(authenticator: authenticator)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
  end
end
