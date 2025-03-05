defmodule PasswordlessWeb.App.EmailLive.Edit do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateVersion

  @components [
    edit: PasswordlessWeb.App.EmailLive.EmailComponent,
    styles: PasswordlessWeb.App.EmailLive.StylesComponent
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    app = socket.assigns.current_app
    template = Passwordless.get_email_template!(app, id)
    languages = EmailTemplateVersion.languages()
    language = List.first(languages)
    version = Passwordless.get_email_template_version(template, language)
    module = Keyword.fetch!(@components, socket.assigns.live_action)

    {:noreply,
     socket
     |> assign(
       version: version,
       template: template,
       language: language,
       languages: languages,
       module: module
     )
     |> assign_template_form(EmailTemplate.changeset(template))
     |> assign_version_form(EmailTemplateVersion.changeset(version))
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/methods/magic-link")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/methods/magic-link")}
  end

  @impl true
  def handle_event("save_template", %{"email_template" => template_params}, socket) do
    save_template(socket, template_params)
  end

  @impl true
  def handle_event("validate_template", %{"email_template" => template_params}, socket) do
    save_template(socket, template_params)
  end

  @impl true
  def handle_event("validate_version", %{"email_template_version" => version_params}, socket) do
    changeset =
      socket.assigns.version
      |> Passwordless.change_email_template_version(version_params)
      |> Map.put(:action, :validate)

    app = socket.assigns.current_app
    template = socket.assigns.template
    language = socket.assigns.language
    current_language = Ecto.Changeset.get_field(changeset, :current_language)

    if language == current_language do
      {:noreply, assign_version_form(socket, changeset)}
    else
      version = Passwordless.get_or_create_email_template_version(app, template, current_language)

      {:noreply,
       socket
       |> assign(version: version, language: current_language)
       |> assign_version_form(EmailTemplateVersion.changeset(version))}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_template_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, template_form: to_form(changeset))
  end

  defp assign_version_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, version_form: to_form(changeset))
  end

  defp apply_action(socket, _action) do
    assign(socket,
      page_title: gettext("Email"),
      page_subtitle: gettext("Edit email template")
    )
  end

  defp save_template(socket, template_params) do
    template = socket.assigns.template

    case Passwordless.update_email_template(template, template_params) do
      {:ok, template} ->
        changeset =
          template
          |> Passwordless.change_email_template()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(template: template)
         |> assign_template_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_template_form(socket, changeset)}
    end
  end

  defp get_flag_icon(:en), do: "flag-us"
  defp get_flag_icon(:de), do: "flag-de"
  defp get_flag_icon(:fr), do: "flag-fr"
end
