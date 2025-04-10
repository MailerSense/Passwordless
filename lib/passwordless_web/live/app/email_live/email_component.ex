defmodule PasswordlessWeb.App.EmailLive.EmailComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Accounts.Notifier
  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.Email
  alias Passwordless.Email.Renderer
  alias Passwordless.EmailTemplateVersion
  alias Passwordless.Locale
  alias Passwordless.Phone
  alias PasswordlessWeb.Email, as: EmailWeb
  alias PasswordlessWeb.Helpers
  alias Swoosh.Email, as: SwooshEmail

  @examples [
    actor: %Actor{
      name: "John Doe",
      user_id: "1234567890",
      language: :en,
      properties: %{
        "key1" => "value1",
        "key2" => "value2"
      },
      email: %Email{
        address: "john.doe@megacorp.com"
      },
      phone: %Phone{
        canonical: "+491234567890"
      }
    },
    action: %Action{
      name: "login"
    }
  ]

  @impl true
  def update(assigns, socket) do
    language = assigns.language

    languages =
      Enum.map(EmailTemplateVersion.languages(), fn code -> {Keyword.fetch!(Locale.languages(), code), code} end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       languages: languages,
       flag_icon: get_flag_icon(language)
     )}
  end

  @impl true
  def handle_event("send_preview", _params, socket) do
    opts = [{:app, socket.assigns.current_app} | @examples]
    user = socket.assigns.current_user
    template = socket.assigns.template
    version = socket.assigns.version
    user_name = Helpers.user_name(user)
    user_email = Helpers.user_email(user)

    with {:ok,
          %{
            subject: subject,
            html_content: html_content,
            text_content: text_content
          }} <- Renderer.render(version, %{}, opts) do
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
