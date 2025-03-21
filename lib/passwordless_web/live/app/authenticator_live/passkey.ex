defmodule PasswordlessWeb.App.AuthenticatorLive.Passkey do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Authenticators.Passkey
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    passkey = Repo.preload(app, :passkey).passkey
    changeset = Passwordless.change_passkey(passkey)

    intervals =
      Enum.map(Passkey.intervals(), fn interval ->
        {Phoenix.Naming.humanize(interval), interval}
      end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(passkey: passkey, intervals: intervals)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"passkey" => passkey_params}, socket) do
    save_passkey(socket, passkey_params)
  end

  @impl true
  def handle_event("validate", %{"passkey" => passkey_params}, socket) do
    save_passkey(socket, passkey_params)
  end

  # Private

  defp save_passkey(socket, params) do
    case Passwordless.update_passkey(socket.assigns.passkey, params) do
      {:ok, passkey} ->
        changeset =
          passkey
          |> Passwordless.change_passkey()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(passkey: passkey)
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
