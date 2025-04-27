defmodule PasswordlessWeb.EmailSubscriptionController do
  use PasswordlessWeb, :controller

  def unsubscribe(%Plug.Conn{} = conn, %{"token" => token}) when is_binary(token) do
    case Passwordless.unsubscribe_email(token, "one-click-post") do
      {:ok, _} -> conn |> put_status(200) |> json(%{status: 200})
      {:error, _} -> conn |> put_status(400) |> json(%{status: 400})
    end
  end
end
