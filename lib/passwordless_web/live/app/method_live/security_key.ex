defmodule PasswordlessWeb.App.MethodLive.SecurityKey do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    security_key = Repo.preload(app, :security_key).security_key
    changeset = Passwordless.change_security_key(security_key)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(security_key: security_key)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"security_key" => security_key_params}, socket) do
    save_security_key(socket, security_key_params)
  end

  @impl true
  def handle_event("validate", %{"security_key" => security_key_params}, socket) do
    save_security_key(socket, security_key_params)
  end

  # Private

  defp save_security_key(socket, params) do
    case Passwordless.update_security_key(socket.assigns.security_key, params) do
      {:ok, security_key} ->
        changeset =
          security_key
          |> Passwordless.change_security_key()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(security_key: security_key)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
    |> assign(expected_origins: Ecto.Changeset.fetch_field!(changeset, :expected_origins))
  end
end
