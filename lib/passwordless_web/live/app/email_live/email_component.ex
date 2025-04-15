defmodule PasswordlessWeb.App.EmailLive.EmailComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Accounts.Notifier
  alias Passwordless.Email.Renderer
  alias Passwordless.EmailTemplateLocale
  alias Passwordless.Locale
  alias PasswordlessWeb.Email, as: EmailWeb
  alias PasswordlessWeb.Helpers
  alias Swoosh.Email, as: SwooshEmail

  @impl true
  def update(assigns, socket) do
    language = assigns.language

    languages =
      Enum.map(EmailTemplateLocale.languages(), fn code ->
        {Keyword.fetch!(Locale.languages(), code), code}
      end)

    opts = [{:app, assigns.current_app} | Renderer.demo_opts()]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       languages: languages,
       flag_icon: get_flag_icon(language),
       variables: Renderer.prepare_variables(assigns.locale, Renderer.demo_variables(), opts)
     )}
  end

  @impl true
  def handle_event("send_preview", _params, socket) do
    opts = [{:app, socket.assigns.current_app} | Renderer.demo_opts()]
    user = socket.assigns.current_user
    locale = socket.assigns.locale
    user_name = Helpers.user_name(user)
    user_email = Helpers.user_email(user)

    with {:ok,
          %{
            subject: subject,
            html_content: html_content,
            text_content: text_content
          }} <- Renderer.render(locale, Renderer.demo_variables(), opts) do
      EmailWeb.auth_email()
      |> SwooshEmail.to({user_name, user_email})
      |> SwooshEmail.subject(gettext("[Test] %{name}", name: subject))
      |> SwooshEmail.html_body(html_content)
      |> SwooshEmail.text_body(text_content)
      |> Notifier.deliver(via: Notifier.system_domain(EmailWeb.auth_email_domain()))
    end

    LiveToast.send_toast(:info, "Preview email sent.", title: gettext("Success"))

    {:noreply, socket}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp get_flag_icon(:en), do: "flag-gb"
  defp get_flag_icon(:de), do: "flag-de"
  defp get_flag_icon(:fr), do: "flag-fr"
end
