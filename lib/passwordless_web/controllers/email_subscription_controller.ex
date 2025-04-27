defmodule PasswordlessWeb.EmailSubscriptionController do
  use PasswordlessWeb, :controller

  def unsubscribe(%Plug.Conn{} = conn, %{"token" => token}) when is_binary(token) do
    case Passwordless.unsubscribe_email(token, "one-click-post") do
      {:ok, _} ->
        conn
        |> put_flash(:info, "You have been unsubscribed.")
        |> redirect(to: "/")

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid unsubscribe link!")
        |> redirect(to: "/")
    end
  end
end
