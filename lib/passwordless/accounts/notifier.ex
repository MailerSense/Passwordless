defmodule Passwordless.Accounts.Notifier do
  @moduledoc """
  When sending an email we use the functions in Passwordless.Email to generate the Email struct ready for Swoosh to send off.
  Here we generate an Email struct based on a user and then deliver it.
  For some emails, we also filter which users can actually be sent an email (see can_receive_mail?/1)
  """

  alias Passwordless.Accounts.User
  alias Passwordless.Mailer
  alias Passwordless.MailerExecutor
  alias PasswordlessWeb.Email

  @doc """
  Deliver instructions to confirm User.
  """
  def deliver_confirmation_instructions(%User{email: email}, url) when is_binary(url) do
    email
    |> Email.confirm_register_email(url)
    |> deliver()
  end

  @doc """
  Deliver instructions to reset the user password.
  """
  def deliver_reset_password_instructions(%User{email: email}, url) when is_binary(url) do
    email
    |> Email.reset_password(url)
    |> deliver()
  end

  @doc """
  Deliver instructions to update the user email.
  """
  def deliver_update_email_instructions(%User{email: email}, url) when is_binary(url) do
    email
    |> Email.change_email(url)
    |> deliver()
  end

  @doc """
  Deliver instructions to accept an invite to an organization.
  """
  def deliver_org_invitation(org, invitation, url) do
    org
    |> Email.org_invitation(invitation, url)
    |> deliver()
  end

  @doc """
  Deliver a pin code to sign in without a password.
  """
  def deliver_passwordless_token(%User{email: email}, url) when is_binary(url) do
    email
    |> Email.passwordless_token(url)
    |> deliver()
  end

  @doc """
  Deliver a pin code to sign in without a password.
  """
  def deliver_contact_form_submission(email, name, message) do
    email
    |> Email.contact_form(name, message)
    |> deliver()
  end

  # Private

  defp deliver(%Swoosh.Email{} = email) do
    with {:ok, _job} <- enqueue_worker(Mailer.to_map(email)) do
      {:ok, email}
    end
  end

  defp enqueue_worker(email) do
    %{email: email}
    |> MailerExecutor.new()
    |> Oban.insert()
  end
end
