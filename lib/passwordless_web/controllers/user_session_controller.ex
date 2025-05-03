defmodule PasswordlessWeb.UserSessionController do
  use PasswordlessWeb, :controller

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias PasswordlessWeb.UserAuth

  @doc """
  Logs user in using email and password.
  """
  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      %User{} = user ->
        UserAuth.log_in(conn, user, via: :password)

      _ ->
        conn
        |> put_flash(:error, gettext("Invalid email or password."))
        |> redirect(to: ~p"/auth/sign-in")
    end
  end

  @doc """
  Logs user in using a passwordless token sent to them via email.
  """
  def create_from_token(conn, %{"token" => token} = params) when is_binary(token) do
    create_user_from_token(conn, params, token)
  end

  @doc """
  Logs user in using a passwordless token from the email OTP form.
  """
  def create_from_token_form(conn, %{"auth" => %{"sign_in_token" => token}} = params) when is_binary(token) do
    create_user_from_token(conn, params, token)
  end

  @doc """
  Logs the user out
  """
  def delete(conn, _params) do
    UserAuth.log_out(conn)
  end

  # Private

  defp create_user_from_token(%Plug.Conn{} = conn, params, token) when is_binary(token) do
    case Accounts.get_user_by_token(token, :passwordless_sign_in) do
      %User{} = user ->
        user_return_to = if Util.blank?(params["user_return_to"]), do: nil, else: params["user_return_to"]

        conn = if user_return_to, do: put_session(conn, :user_return_to, user_return_to), else: conn

        # Delete the passwordless login token now that it has been used
        Accounts.delete_user_token(user, token, :passwordless_sign_in)

        # Activate user if not already
        Accounts.activate_user!(user)

        # Confirm user if not already
        Accounts.confirm_user!(user)

        # Log user in
        UserAuth.log_in(conn, user, via: :passwordless)

      _ ->
        redirect(conn, to: ~p"/auth/sign-in/passwordless")
    end
  end
end
