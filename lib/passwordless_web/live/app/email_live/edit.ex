defmodule PasswordlessWeb.App.EmailLive.Edit do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Email.Renderer
  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateLocale
  alias Passwordless.EmailTemplateStyle
  alias Passwordless.Locale

  @default PasswordlessWeb.App.EmailLive.EmailComponent
  @components [
    edit: PasswordlessWeb.App.EmailLive.EmailComponent,
    code: PasswordlessWeb.App.EmailLive.CodeComponent,
    files: PasswordlessWeb.App.EmailLive.FileComponent
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
        locale = Passwordless.get_or_create_email_template_locale(app, template, language)
        locale = EmailTemplateLocale.put_current_language(locale, language)

        socket
        |> assign(locale: locale, template: template, language: language)
        |> assign_template_form(EmailTemplate.changeset(template))
        |> assign_locale_form(EmailTemplateLocale.changeset(locale))
      end

    module = Keyword.get(@components, socket.assigns.live_action, @default)
    delete? = Map.has_key?(params, "delete")
    return_to = Map.get(params, "return_to")

    {:noreply,
     socket
     |> assign(delete?: delete?, return_to: return_to, module: module)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/emails/#{socket.assigns.template}/#{socket.assigns.language}/#{socket.assigns.live_action}"
     )}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/emails/#{socket.assigns.template}/#{socket.assigns.language}/#{socket.assigns.live_action}"
     )}
  end

  @impl true
  def handle_event("validate_template", %{"email_template" => template_params}, socket) do
    save_template(socket, template_params)
  end

  @impl true
  def handle_event("save_template", %{"email_template" => template_params}, socket) do
    save_template(socket, template_params)
  end

  @impl true
  def handle_event("save_locale", %{"email_template_locale" => locale_params}, socket) do
    opts = [{:app, socket.assigns.current_app} | Renderer.demo_opts()]
    locale = socket.assigns.locale

    case Passwordless.update_email_template_locale(locale, locale_params, opts) do
      {:ok, locale} ->
        changeset =
          locale
          |> Passwordless.change_email_template_locale(%{}, opts)
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> put_toast(:info, "Email template saved.", title: gettext("Success"))
         |> assign(locale: locale)
         |> assign_locale_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_locale_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("validate_locale", %{"email_template_locale" => locale_params}, socket) do
    opts = [{:app, socket.assigns.current_app} | Renderer.demo_opts()]

    changeset =
      socket.assigns.locale
      |> Passwordless.change_email_template_locale(locale_params, opts)
      |> Map.put(:action, :validate)

    template = socket.assigns.template
    language = socket.assigns.language
    locale = socket.assigns.locale
    style = locale.style
    current_style = Ecto.Changeset.get_field(changeset, :style)
    current_language = Ecto.Changeset.get_field(changeset, :current_language)

    socket =
      cond do
        not changeset.valid? and Keyword.has_key?(changeset.errors, :mjml_body) ->
          socket
          |> put_toast(
            :error,
            gettext("Failed to validate template: %{error}",
              error: Jason.encode!(Util.humanize_changeset_errors(changeset))
            ),
            title: gettext("Error")
          )
          |> assign_locale_form(changeset)

        style != current_style ->
          opts = [{:app, socket.assigns.current_app} | Renderer.demo_opts()]
          Passwordless.persist_template_locale_style!(locale)

          changeset =
            case Passwordless.get_template_locale_style(locale, current_style) do
              %EmailTemplateStyle{} = style ->
                locale_params =
                  Map.put(locale_params, "mjml_body", style.mjml_body)

                socket.assigns.locale
                |> Passwordless.change_email_template_locale(locale_params, opts)
                |> Map.put(:action, :validate)

              _ ->
                changeset
            end

          assign_locale_form(socket, changeset)

        language != current_language ->
          socket
          |> assign(locale_form: nil)
          |> push_patch(to: ~p"/emails/#{template}/#{current_language}/edit")

        true ->
          assign_locale_form(socket, changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("format_code", _params, socket) do
    case get_in(socket.assigns, [Access.key(:locale_form), Access.key(:source)]) do
      %Ecto.Changeset{valid?: true} = changeset ->
        formatted =
          changeset
          |> Ecto.Changeset.get_field(:mjml_body)
          |> Passwordless.Formatter.format!(:html)

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

  defp assign_locale_form(socket, %Ecto.Changeset{} = changeset) do
    opts = [{:app, socket.assigns.current_app} | Renderer.demo_opts()]

    locale = %EmailTemplateLocale{
      subject: Ecto.Changeset.get_field(changeset, :subject),
      preheader: Ecto.Changeset.get_field(changeset, :preheader),
      mjml_body: Ecto.Changeset.get_field(changeset, :mjml_body)
    }

    current_style = Ecto.Changeset.get_field(changeset, :style)
    current_language = Ecto.Changeset.get_field(changeset, :current_language)

    socket =
      case Renderer.render(locale, Renderer.demo_variables(), opts) do
        {:ok, %{html_content: html_content}} ->
          assign(socket, preview: html_content)

        {:error, _} ->
          assign(socket, preview: nil)
      end

    socket
    |> assign(locale_form: to_form(changeset))
    |> assign(
      current_style: current_style,
      current_language: current_language,
      current_language_readable: Keyword.fetch!(Locale.languages(), current_language)
    )
  end

  defp apply_action(socket, _action, %{"delete" => _}) do
    assign(socket,
      page_title: gettext("Reset email template"),
      page_subtitle:
        gettext(
          "Are you sure you want to reset this email template? Any customizations to the subject, preheader and content will be erased and replaced with default values."
        )
    )
  end

  defp apply_action(socket, _action, %{"variables" => _}) do
    assign(socket,
      page_title: gettext("Variables"),
      page_subtitle:
        gettext(
          "Email templates can be personalized using dynamic variables, such as the user's name. Section below lists all available variables, their contexts and usage patterns. For nested objects, use dot notation, e.g. {{ user.name }} or {{ user.properties.key1 }}."
        )
    )
  end

  defp apply_action(socket, _action, _params) do
    assign(socket,
      page_title: gettext("Email"),
      page_subtitle: gettext("Edit email template")
    )
  end

  defp has_unsaved_changes?(socket) do
    case get_in(socket.assigns, [
           Access.key(:locale_form),
           Access.key(:source),
           Access.key(:changes)
         ]) do
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
