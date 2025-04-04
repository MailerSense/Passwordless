defmodule PasswordlessWeb.UserConfirmationController do
  use PasswordlessWeb, :controller

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias PasswordlessWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  def update(conn, %{"token" => token}) do
    case Accounts.confirm_user_by_token(token) do
      {:ok, user} ->
        Activity.log_async(:"user.confirm", %{user: user})

        Organizations.sync_user_invitations(user)

        user_id = user.id

        case conn.assigns[:current_user] do
          %User{id: ^user_id} ->
            redirect(conn, to: PasswordlessWeb.Helpers.home_path(user))

          %User{} ->
            conn
            |> UserAuth.put_user_into_session(user)
            |> redirect(to: PasswordlessWeb.Helpers.home_path(user))

          _ ->
            conn
            |> UserAuth.put_user_into_session(user)
            |> redirect(to: PasswordlessWeb.Helpers.home_path(user))
        end

      _ ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case conn.assigns[:current_user] do
          %User{} = user ->
            if User.confirmed?(user) do
              redirect(conn, to: PasswordlessWeb.Helpers.home_path(user))
            else
              conn
              |> put_flash(:error, gettext("User confirmation link is invalid or it has expired!"))
              |> redirect(to: "/")
            end

          _ ->
            conn
            |> put_flash(:error, gettext("User confirmation link is invalid or it has expired!"))
            |> redirect(to: "/")
        end
    end
  end

  def resend_confirm_email(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{} = user ->
        if User.confirmed?(user) do
          conn
          |> put_flash(:info, gettext("You are already confirmed."))
          |> redirect(to: PasswordlessWeb.Helpers.home_path(user))
        else
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/app/user/settings/confirm-email/#{&1}")
          )

          conn
          |> put_flash(
            :info,
            gettext("A new email has been sent to %{user_email}",
              user_email: user.email
            )
          )
          |> redirect(to: ~p"/auth/confirm")
        end

      _ ->
        conn
        |> put_flash(:error, gettext("You must be signed in to resend confirmation instructions!"))
        |> redirect(to: "/")
    end
  end

  def unconfirmed(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{} = user ->
        if User.confirmed?(user),
          do: redirect(conn, to: PasswordlessWeb.Helpers.home_path(user)),
          else: render(conn, page_title: gettext("Unconfirmed email"))

      _ ->
        render(conn, page_title: gettext("Unconfirmed email"))
    end
  end
end
