defmodule PasswordlessWeb.App.MethodLive.MagicLink do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    magic_link = Repo.preload(app, :magic_link).magic_link
    changeset = Passwordless.change_magic_link(magic_link)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(magic_link: magic_link)
     |> assign_form(changeset)}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
  end
end
