defmodule PasswordlessWeb.App.MethodLive.Whatsapp do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Locale
  alias Passwordless.Methods.WhatsApp
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    whatsapp = Repo.preload(app, :whatsapp).whatsapp
    changeset = Passwordless.change_whatsapp(whatsapp)

    languages =
      Enum.map(WhatsApp.languages(), fn code -> {Keyword.fetch!(Locale.languages(), code), code} end)

    flag_mapping = fn
      nil -> "flag-gb"
      "en" -> "flag-gb"
      :en -> "flag-gb"
      code -> "flag-#{code}"
    end

    preview = """
    Your #{app.display_name} verification code is 123456. To stop receiving these messages, visit #{app.website}/whatsapp-opt-out?code=#{app.id}.
    """

    {:ok,
     socket
     |> assign(assigns)
     |> assign(whatsapp: whatsapp, preview: preview, languages: languages, flag_mapping: flag_mapping)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"whatsapp" => whatsapp_params}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"whatsapp" => whatsapp_params}, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
  end
end
