defmodule PasswordlessWeb.App.AuthenticatorLive.MagicLink do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Authenticators.MagicLink
  alias Passwordless.Domain
  alias Passwordless.Email.Renderer
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    app = Repo.preload(app, [:magic_link])

    magic_link = app.magic_link
    domain = Passwordless.get_fallback_domain!(app, :email)
    changeset = Passwordless.change_magic_link(magic_link)

    email_template = Repo.preload(magic_link, :email_template).email_template
    email_template_locale = Passwordless.get_email_template_locale(email_template)

    socket =
      case Renderer.render(email_template_locale, Renderer.demo_variables(), [{:app, app} | Renderer.demo_opts()]) do
        {:ok, %{html_content: html_content}} ->
          assign(socket, preview: html_content)

        {:error, _} ->
          assign(socket, preview: nil)
      end

    fingerprint_factors = [
      %{
        icon: nil,
        icon_class: nil,
        label: gettext("Device ID"),
        value: "device_id",
        description: gettext("Unique ID provided by your app")
      },
      %{
        icon: nil,
        icon_class: nil,
        label: gettext("IP Address"),
        value: "ip_address",
        description: gettext("The IP address of the user device")
      },
      %{
        icon: nil,
        icon_class: nil,
        label: gettext("User Agent"),
        value: "user_agent",
        description: gettext("As reported by the browser")
      }
    ]

    icon_mapping = fn
      nil -> "remix-checkbox-circle-line"
      "none" -> "remix-checkbox-circle-line"
      :none -> "remix-checkbox-circle-line"
      "click" -> "remix-cursor-line"
      :click -> "remix-cursor-line"
      "short_code" -> "remix-hashtag"
      :short_code -> "remix-hashtag"
    end

    behaviors =
      Enum.map(MagicLink.behaviors(), fn step ->
        {label, description} = behaviour_translation(step)

        %{
          label: label,
          value: step,
          description: description,
          disabled: step not in MagicLink.behaviors_enabled()
        }
      end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       domain: domain,
       magic_link: magic_link,
       behaviors: behaviors,
       icon_mapping: icon_mapping,
       email_template: email_template,
       fingerprint_factors: fingerprint_factors
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"magic_link" => magic_link_params}, socket) do
    save_magic_link(socket, magic_link_params)
  end

  @impl true
  def handle_event("validate", %{"magic_link" => magic_link_params}, socket) do
    save_magic_link(socket, magic_link_params)
  end

  # Private

  defp behaviour_translation(:authenticate),
    do: {gettext("Redirect"), gettext("Authenticate user immediately after clicking the link")}

  defp behaviour_translation(:click),
    do: {gettext("Press button"), gettext("Ask user to click a button to confirm the action")}

  defp behaviour_translation(:short_code),
    do: {gettext("Short code"), gettext("Ask user to type a short-code they were shown when the link was sent")}

  defp save_magic_link(socket, params) do
    opts = [domain: socket.assigns[:domain]]

    case Passwordless.update_magic_link(socket.assigns.magic_link, params, opts) do
      {:ok, magic_link} ->
        changeset =
          magic_link
          |> Passwordless.change_magic_link()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(magic_link: magic_link)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
    |> assign(fingerprint_device: Ecto.Changeset.fetch_field!(changeset, :fingerprint_device))
  end
end
