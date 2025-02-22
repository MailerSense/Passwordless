defmodule PasswordlessWeb.Auth.ResetPasswordLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Activity

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_user_and_token(params)
      |> assign(page_title: gettext("Reset password"))

    socket =
      case socket.assigns[:user] do
        %User{} = user -> assign_form(socket, Accounts.change_user_password(user))
        _ -> socket
      end

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  @impl true
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, user} ->
        Activity.log_async(:user, :"user.reset_password", %{user: user})

        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/auth/sign-in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # Private

  defp assign_user_and_token(socket, %{"token" => token}) do
    case Accounts.get_user_by_reset_password_token(token) do
      %User{} = user ->
        assign(socket, user: user, token: token)

      _ ->
        socket
        |> put_flash(:error, gettext("Reset password link is invalid or it has expired!"))
        |> redirect(to: home_path(socket.assigns[:current_user]))
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
