defmodule PasswordlessWeb.App.AuthenticatorLive.RecoveryCodes do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  @spec update(%{:app => Passwordless.App.t(), optional(any()) => any()}, any()) :: {:ok, any()}
  def update(%{app: %App{} = app} = assigns, socket) do
    recovery_codes = Repo.preload(app, :recovery_codes).recovery_codes
    changeset = Passwordless.change_recovery_codes(recovery_codes)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(recovery_codes: recovery_codes)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"recovery_codes" => recovery_codes_params}, socket) do
    save_recovery_codes(socket, recovery_codes_params)
  end

  @impl true
  def handle_event("validate", %{"recovery_codes" => recovery_codes_params}, socket) do
    save_recovery_codes(socket, recovery_codes_params)
  end

  # Private

  defp save_recovery_codes(socket, params) do
    case Passwordless.update_recovery_codes(socket.assigns.recovery_codes, params) do
      {:ok, recovery_codes} ->
        changeset =
          recovery_codes
          |> Passwordless.change_recovery_codes()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(recovery_codes: recovery_codes)
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
