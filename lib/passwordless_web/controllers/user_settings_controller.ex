defmodule PasswordlessWeb.UserSettingsController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias PasswordlessWeb.UserAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params, _user) do
    render(conn, "edit.html")
  end

  def update_password(conn, %{"current_password" => password, "user" => user_params} = _params, %User{} = user) do
    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, gettext("Password updated successfully."))
        |> put_session(:user_return_to, ~p"/app/password")
        |> UserAuth.log_in(user, via: :password_change)

      {:error, changeset} ->
        conn
        |> put_flash(
          :error,
          PasswordlessWeb.CoreComponents.combine_changeset_error_messages(changeset)
        )
        |> redirect(to: ~p"/app/password")
    end
  end

  def confirm_email(conn, %{"token" => token}, %User{} = user) do
    case Accounts.update_user_email(user, token) do
      {:ok, user} ->
        Activity.log_async(:"user.confirm_email", %{user: user})

        Organizations.sync_user_invitations(user)

        conn
        |> put_flash(:info, gettext("Email changed successfully."))
        |> redirect(to: ~p"/app/profile")

      _ ->
        conn
        |> put_flash(:error, gettext("Email change link is invalid or it has expired!"))
        |> redirect(to: ~p"/app/profile")
    end
  end

  # Private

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
