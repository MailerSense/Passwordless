defmodule PasswordlessWeb.UserImpersonationController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Security.Guard
  alias Passwordless.Security.Policy.Accounts, as: AccountsPolicy
  alias PasswordlessWeb.Helpers
  alias PasswordlessWeb.UserAuth

  def create(conn, %{"user_id" => user_id}, %User{} = impersonator) do
    user = Accounts.get_user!(user_id)

    if Guard.permit(AccountsPolicy, impersonator, :"user.impersonate", user) do
      conn
      |> put_flash(:info, gettext("Impersonating %{name}", name: Helpers.user_name(user)))
      |> impersonate_user(impersonator, user)
    else
      conn
      |> put_flash(:error, gettext("Invalid user or not permitted"))
      |> redirect(to: ~p"/admin/users")
    end
  end

  def delete(conn, _params, %User{} = user) do
    if Helpers.user_impersonated?(user) do
      impersonator_user = Accounts.get_user!(user.current_impersonator.id)

      conn =
        conn
        |> delete_session(:impersonator_user_id)
        |> UserAuth.put_user_into_session(impersonator_user)

      info = gettext("You're back as %{name}", name: Helpers.user_name(impersonator_user))

      conn
      |> put_flash(:info, info)
      |> redirect(to: ~p"/admin/users")
    else
      redirect(conn, to: ~p"/")
    end
  end

  # Private

  defp impersonate_user(conn, %User{} = impersonator_user, %User{} = user) do
    conn =
      conn
      |> UserAuth.put_user_into_session(user)
      |> put_session(:impersonator_user_id, impersonator_user.id)

    UserAuth.redirect_user_after_login(conn, user)
  end
end
