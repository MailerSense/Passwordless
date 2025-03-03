defmodule Passwordless.EmailTemplates do
  @moduledoc false

  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.App

  def template(_app, _kind, _language, opts \\ [])

  def template(%App{} = app, :magic_link_first_sign_in, :en, _opts) do
    %{
      subject: gettext("Welcome to %{name}", name: app.display_name),
      preheader: gettext("Click the link below to confirm your email address.")
    }
  end

  def template(%App{} = app, :magic_link_sign_in, :en, _opts) do
    %{
      subject: gettext("Sign in to %{name}", name: app.display_name),
      preheader: gettext("Click the link below to sign in.")
    }
  end

  def template(%App{} = app, :email_otp_first_sign_in, :en, _opts) do
    %{
      subject: gettext("Welcome to %{name}", name: app.display_name),
      preheader: gettext("Use the code below to confirm your email address.")
    }
  end

  def template(%App{} = app, :email_otp_sign_in, :en, _opts) do
    %{
      subject: gettext("Sign in to %{name}", name: app.display_name),
      preheader: gettext("Use the code below to sign in.")
    }
  end
end
