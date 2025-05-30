defmodule PasswordlessWeb.App.AuthenticatorLive.Social do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  @spec update(%{:app => Passwordless.App.t(), optional(any()) => any()}, any()) :: {:ok, any()}
  def update(%{app: %App{} = app} = assigns, socket) do
    social = Repo.preload(app, :social).social
    changeset = Passwordless.change_social(social)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(social: social)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"social" => social_params}, socket) do
    save_social(socket, social_params)
  end

  @impl true
  def handle_event("validate", %{"social" => social_params}, socket) do
    save_social(socket, social_params)
  end

  # Private

  defp save_social(socket, params) do
    case Passwordless.update_social(socket.assigns.social, params) do
      {:ok, social} ->
        changeset =
          social
          |> Passwordless.change_social()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(social: social)
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
