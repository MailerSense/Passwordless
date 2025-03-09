defmodule PasswordlessWeb.App.EmailLive.Edit do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateVersion

  @components [
    edit: PasswordlessWeb.App.EmailLive.EmailComponent,
    code: PasswordlessWeb.App.EmailLive.CodeComponent,
    styles: PasswordlessWeb.App.EmailLive.StylesComponent
  ]

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_params(%{"id" => id, "language" => language} = params, _url, socket) do
    socket =
      if has_unsaved_changes?(socket) do
        socket
      else
        app = socket.assigns.current_app
        template = Passwordless.get_email_template!(app, id)
        language = String.to_existing_atom(language)
        version = Passwordless.get_or_create_email_template_version(app, template, language)
        version = EmailTemplateVersion.put_current_language(version, language)

        socket
        |> assign(version: version, template: template, language: language)
        |> assign_template_form(EmailTemplate.changeset(template))
        |> assign_version_form(EmailTemplateVersion.changeset(version))
      end

    module = Keyword.fetch!(@components, socket.assigns.live_action)
    delete? = Map.has_key?(params, "delete")

    {:noreply,
     socket
     |> assign(delete?: delete?, module: module)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/app/emails/#{socket.assigns.template}/#{socket.assigns.language}/#{socket.assigns.live_action}"
     )}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/app/emails/#{socket.assigns.template}/#{socket.assigns.language}/#{socket.assigns.live_action}"
     )}
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
  def handle_event("save_version", %{"email_template_version" => version_params}, socket) do
    version = socket.assigns.version

    case Passwordless.update_email_template_version(version, version_params) do
      {:ok, version} ->
        changeset =
          version
          |> Passwordless.change_email_template_version()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> put_toast(:info, "Email template saved.", title: gettext("Success"))
         |> assign(version: version)
         |> assign_version_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_version_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("validate_version", %{"email_template_version" => version_params}, socket) do
    changeset =
      socket.assigns.version
      |> Passwordless.change_email_template_version(version_params)
      |> Map.put(:action, :validate)

    template = socket.assigns.template
    language = socket.assigns.language
    current_language = Ecto.Changeset.get_field(changeset, :current_language)

    if language == current_language do
      {:noreply, assign_version_form(socket, changeset)}
    else
      {:noreply,
       socket
       |> assign(version_form: nil)
       |> push_patch(to: ~p"/app/emails/#{template}/#{current_language}/edit")}
    end
  end

  @impl true
  def handle_event("send_preview", _params, socket) do
    {:noreply, put_toast(socket, :info, "Preview email sent.", title: gettext("Success"))}
  end

  @impl true
  def handle_event("format_code", _params, socket) do
    case get_in(socket.assigns, [Access.key(:version_form), Access.key(:source)]) do
      %Ecto.Changeset{valid?: true} = changeset ->
        formatted =
          changeset
          |> Ecto.Changeset.get_field(:mjml_body)
          |> Passwordless.Native.format_code(:html)

        {:noreply, push_event(socket, "get_formatted_code", %{code: formatted})}

      _ ->
        {:noreply, socket}
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
    assign(socket, version_form: to_form(changeset), preview: Ecto.Changeset.get_field(changeset, :html_body))
  end

  defp apply_action(socket, _action, %{"delete" => _}) do
    assign(socket,
      page_title: gettext("Reset email template"),
      page_subtitle: gettext("Are you sure you want to reset this email template? This action cannot be undone.")
    )
  end

  defp apply_action(socket, _action, _params) do
    assign(socket,
      page_title: gettext("Email"),
      page_subtitle: gettext("Edit email template")
    )
  end

  defp has_unsaved_changes?(socket) do
    case get_in(socket.assigns, [Access.key(:version_form), Access.key(:source), Access.key(:changes)]) do
      changes when is_map(changes) and map_size(changes) > 0 -> true
      _ -> false
    end
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
end
