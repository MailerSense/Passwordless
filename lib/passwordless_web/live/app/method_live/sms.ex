defmodule PasswordlessWeb.App.MethodLive.SMS do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    sms = Repo.preload(app, :sms).sms
    changeset = Passwordless.change_sms(sms)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(sms: sms)
     |> assign_form(changeset)}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
  end
end
