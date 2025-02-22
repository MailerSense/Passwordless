defmodule PasswordlessWeb.UserTOTPController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Accounts
  alias PasswordlessWeb.UserAuth

  plug :redirect_if_totp_is_not_pending

  @pending :user_totp_pending

  def new(conn, _params, _user) do
    render(conn, "new.html", error_message: nil, form: to_form(%{}, as: :user))
  end

  def create(conn, %{"user" => user_params}, user) do
    case Accounts.validate_user_totp(user, user_params["code"]) do
      :valid_totp ->
        conn
        |> delete_session(@pending)
        |> UserAuth.redirect_user_after_login(user)

      {:valid_backup_code, remaining} ->
        plural = ngettext("backup code", "backup codes", remaining)

        conn
        |> delete_session(@pending)
        |> put_flash(
          :info,
          gettext(
            "You have %{remaining} %{plural} left. You can generate new ones under the Two-factor authentication section in the Settings page",
            remaining: remaining,
            plural: plural
          )
        )
        |> UserAuth.redirect_user_after_login(user)

      :invalid ->
        render(conn, "new.html",
          error_message: gettext("Invalid two-factor authentication code"),
          form: to_form(%{}, as: :user)
        )
    end
  end

  defp redirect_if_totp_is_not_pending(conn, _opts) do
    if get_session(conn, @pending) do
      conn
    else
      conn
      |> redirect(to: PasswordlessWeb.Helpers.home_path(conn.assigns.current_user))
      |> halt()
    end
  end
end
