defmodule PasswordlessWeb.EmailTestingController do
  use PasswordlessWeb, :controller

  alias Passwordless.Mailer
  alias Passwordless.Organizations.Org
  alias PasswordlessWeb.Email

  @default_template "template"

  # How to add a new email notification:
  # 1. create new function in UserMailer
  # 2. in this file add to @email_templates
  # 3. in this file add a new generate_email function

  @email_templates [
    "template",
    "register_confirm_email",
    "reset_password",
    "change_email",
    "org_invitation",
    "passwordless_token",
    "contact_form"
  ]

  # Keep this to copy elements from it into your emails
  defp generate_email("template", current_user) do
    Email.template(current_user.email)
  end

  defp generate_email("register_confirm_email", current_user) do
    {token_signed, _token} = Passwordless.Accounts.Token.new(current_user, :email_confirmation)
    Email.confirm_register_email(current_user.email, url(~p"/auth/confirm/#{token_signed}"))
  end

  defp generate_email("reset_password", current_user) do
    {token_signed, _token} = Passwordless.Accounts.Token.new(current_user, :password_reset)
    Email.reset_password(current_user.email, url(~p"/auth/reset-password/#{token_signed}"))
  end

  defp generate_email("change_email", current_user) do
    {token_signed, _token} = Passwordless.Accounts.Token.new(current_user, :email_change)
    Email.change_email(current_user.email, url(~p"/app/user/settings/confirm-email/#{token_signed}"))
  end

  defp generate_email("org_invitation", current_user) do
    org = %Org{name: "Petal Pro"}
    invitation = %{email: current_user.email, user_id: current_user.id}
    Email.org_invitation(org, invitation, "#")
  end

  defp generate_email("passwordless_token", current_user) do
    {token_signed, _token} = Passwordless.Accounts.Token.new(current_user, :passwordless_sign_in)
    Email.passwordless_token(current_user.email, url(~p"/auth/sign-in/passwordless/complete/#{token_signed}"))
  end

  defp generate_email("contact_form", current_user) do
    Email.contact_form(current_user.email, "Marcin Praski", "Whut be dat shit")
  end

  def index(conn, _params) do
    redirect(conn, to: ~p"/dev/emails/preview/#{@default_template}")
  end

  def sent(conn, _params) do
    render(conn)
  end

  def preview(conn, %{"email_name" => email_name}) do
    conn
    |> put_root_layout(html: {PasswordlessWeb.Layouts, :empty})
    |> render(
      "index.html",
      %{
        email: generate_email(email_name, conn.assigns.current_user),
        email_name: email_name,
        email_options: @email_templates,
        iframe_url: url(~p"/dev/emails/show/#{email_name}")
      }
    )
  end

  def send_test_email(conn, %{"email_name" => email_name}) do
    if Util.email_valid?(conn.assigns.current_user.email) do
      email_name
      |> generate_email(conn.assigns.current_user)
      |> Mailer.deliver()

      conn
      |> put_flash(:info, "Email sent")
      |> redirect(to: ~p"/dev/emails/preview/#{email_name}")
    else
      conn
      |> put_flash(:error, "Email invalid")
      |> redirect(to: ~p"/dev/emails/preview/#{email_name}")
    end
  end

  def show_html(conn, %{"email_name" => email_name}) do
    email = generate_email(email_name, conn.assigns.current_user)

    conn
    |> put_layout(false)
    |> html(email.html_body)
  end
end
