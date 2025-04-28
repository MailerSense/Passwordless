defmodule PasswordlessWeb.Email do
  @moduledoc """
  Houses functions that generate Swoosh email structs.
  An Swoosh email struct can be delivered by a Swoosh mailer (see mailer.ex & user_notifier.ex). Eg:

      Passwordless.Email.confirm_register_email(user.email, url)
      |> Passwordless.Mailer.deliver()
  """

  use PasswordlessWeb.EmailMacros
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.Organizations.Org

  def template(email) do
    support_email()
    |> to(email)
    |> subject(gettext("Template for showing how to do headings, buttons etc in emails"))
    |> render_body("template.html")
    |> premail()
  end

  def confirm_register_email(email, url) do
    auth_email()
    |> to(email)
    |> subject(gettext("Confirm instructions"))
    |> render_body("confirm_register_email.html", %{url: url})
    |> premail()
  end

  def reset_password(email, url) do
    auth_email()
    |> to(email)
    |> subject(gettext("Reset password"))
    |> render_body("reset_password.html", %{url: url})
    |> premail()
  end

  def change_email(email, url) do
    auth_email()
    |> to(email)
    |> subject(gettext("Change email"))
    |> render_body("change_email.html", %{url: url})
    |> premail()
  end

  def org_invitation(%Org{} = org, invitation, url) do
    auth_email()
    |> to(invitation.email)
    |> subject(gettext("Invitation to join %{org_name}", org_name: org.name))
    |> render_body("org_invitation.html", %{org: org, invitation: invitation, url: url})
    |> premail()
  end

  def passwordless_token(email, url) do
    auth_email()
    |> to(email)
    |> subject(gettext("%{app} Login Link", app: Passwordless.config(:app_name)))
    |> render_body("passwordless_token.html", %{url: url})
    |> premail()
  end

  def email_otp(email, code) do
    auth_email()
    |> to(email)
    |> subject(gettext("%{app} OTP Code", app: Passwordless.config(:app_name)))
    |> render_body("email_otp.html", %{code: code})
    |> premail()
  end

  def contact_form(email, name, message) do
    support_email()
    |> to("hello@passwordless.tools")
    |> subject(gettext("Contact Form Submission"))
    |> render_body("contact_form.html", %{name: name, email_address: email, message: message})
    |> premail()
  end

  # For when you don't need any HTML and just want to send text
  def text_only_email(to_email, subject, body, cc \\ []) do
    support_email()
    |> to(to_email)
    |> subject(subject)
    |> text_body(body)
    |> cc(cc)
  end

  # Inlines your CSS and adds a text option (email clients prefer this)
  defp premail(email) do
    html = Premailex.to_inline_css(email.html_body)
    text = Premailex.to_text(email.html_body)

    email
    |> html_body(html)
    |> text_body(text)
  end
end
