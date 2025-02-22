defmodule PasswordlessWeb.UserUeberauthController do
  @moduledoc """
  Write ueberauth callbacks here. A callback is called after a user has successfully authenticated with a provider (eg. Google or Github).
  """
  use PasswordlessWeb, :controller

  alias Passwordless.Accounts
  alias PasswordlessWeb.UserAuth

  plug Ueberauth

  # Google - https://github.com/ueberauth/ueberauth_google
  def callback(%{assigns: %{ueberauth_auth: %{info: user_info}}} = conn, %{"provider" => "google"}) do
    user_params = %{
      name: combine_first_and_last_name(user_info)
    }

    opts = [
      via: :external_provider,
      subject: user_info.email,
      provider: :google
    ]

    case Accounts.get_or_register_user(user_info.email, user_params, opts) do
      {:ok, user} ->
        UserAuth.log_in(conn, Accounts.confirm_user!(user), via: :google)

      {:error, _} ->
        conn
        |> put_flash(:error, gettext("Authentication failed!"))
        |> redirect(to: "/")
    end
  end

  # If no other callbacks match then we assume authentication failed.
  def callback(conn, _params) do
    conn
    |> put_flash(:error, gettext("Authentication failed!"))
    |> redirect(to: "/")
  end

  # Private

  defp combine_first_and_last_name(user_info) do
    [user_info.first_name, user_info.last_name]
    |> Enum.reject(&Util.blank?/1)
    |> Enum.join(" ")
  end
end
