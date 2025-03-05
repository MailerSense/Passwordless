defmodule Passwordless.EmailTemplates do
  @moduledoc false

  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.App

  def get_seed(%App{} = app, kind, language \\ :en) do
    seeds = seeds(app)
    fallback = get_in(seeds, [kind, :en])

    get_in(seeds, [kind, Access.key(language, fallback)])
  end

  def seeds(%App{} = app),
    do: %{
      magic_link_sign_in: %{
        en: %{
          name: gettext("Magic link email template"),
          subject: gettext("Sign in to %{name}", name: app.display_name),
          preheader: gettext("Click the link below to sign in.")
        }
      },
      email_otp_sign_in: %{
        en: %{
          name: gettext("Email OTP email template"),
          subject: gettext("Sign in to %{name}", name: app.display_name),
          preheader: gettext("Use the code below to sign in.")
        }
      }
    }
end
