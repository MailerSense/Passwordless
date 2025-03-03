defmodule PasswordlessWeb.App.EmailLive.Edit do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateVersion
  alias Passwordless.Locale

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    app = socket.assigns.current_app
    kind = List.first(EmailTemplate.kinds())
    editors = Enum.map(EmailTemplate.editors(), fn editor -> {Phoenix.Naming.humanize(editor), editor} end)
    languages = EmailTemplateVersion.languages()
    {:ok, template} = Passwordless.get_email_template(app, kind)
    {:ok, version} = Passwordless.get_email_template_version(app, template, List.first(languages))

    languages_view = Enum.map(languages, fn code -> {Keyword.fetch!(Locale.languages(), code), code} end)

    kinds_view =
      Enum.map(EmailTemplate.hierarchical_kinds(), fn {kind, vals} ->
        {Phoenix.Naming.humanize(kind),
         Enum.map(vals, fn val ->
           Phoenix.Naming.humanize("#{kind}: #{val}")
         end)}
      end)

    flag_mapping = fn
      nil -> "flag-us"
      "en" -> "flag-us"
      :en -> "flag-us"
      code -> "flag-#{code}"
    end

    {:noreply,
     socket
     |> assign(
       kind: kind,
       editors: editors,
       kinds: kinds_view,
       version: version,
       template: template,
       languages: languages_view,
       flag_mapping: flag_mapping
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
end
