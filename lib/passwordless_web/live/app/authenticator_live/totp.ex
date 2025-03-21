defmodule PasswordlessWeb.App.AuthenticatorLive.TOTP do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    totp = Repo.preload(app, :totp).totp
    changeset = Passwordless.change_totp(totp)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(totp: totp)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"totp" => authenticator_params}, socket) do
    save_totp(socket, authenticator_params)
  end

  @impl true
  def handle_event("validate", %{"totp" => authenticator_params}, socket) do
    save_totp(socket, authenticator_params)
  end

  # Private

  defp save_totp(socket, params) do
    case Passwordless.update_totp(socket.assigns.totp, params) do
      {:ok, totp} ->
        changeset =
          totp
          |> Passwordless.change_totp()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(totp: totp)
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
