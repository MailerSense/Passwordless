defmodule PasswordlessWeb.App.AuthenticatorLive.Whatsapp do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Authenticators.WhatsApp
  alias Passwordless.Locale
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    whatsapp = Repo.preload(app, :whatsapp).whatsapp
    changeset = Passwordless.change_whatsapp(whatsapp)

    languages =
      Enum.map(WhatsApp.languages(), fn code ->
        {Keyword.fetch!(Locale.languages(), code), code}
      end)

    flag_mapping = fn
      nil -> "flag-gb"
      "en" -> "flag-gb"
      :en -> "flag-gb"
      code -> "flag-#{code}"
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       whatsapp: whatsapp,
       languages: languages,
       flag_mapping: flag_mapping
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"whats_app" => whatsapp_params}, socket) do
    save_whatsapp(socket, whatsapp_params)
  end

  @impl true
  def handle_event("validate", %{"whats_app" => whatsapp_params}, socket) do
    save_whatsapp(socket, whatsapp_params)
  end

  # Private

  defp save_whatsapp(socket, params) do
    case Passwordless.update_whatsapp(socket.assigns.whatsapp, params) do
      {:ok, whatsapp} ->
        changeset =
          whatsapp
          |> Passwordless.change_whatsapp()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(whatsapp: whatsapp)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    preview =
      changeset
      |> Ecto.Changeset.fetch_field!(:language)
      |> Passwordless.SMS.format_message!(
        url: socket.assigns.app.website,
        code: Passwordless.OTP.generate_code(),
        app_name: socket.assigns.app.name
      )

    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
    |> assign(preview: preview)
  end
end
