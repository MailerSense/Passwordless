defmodule PasswordlessApi.UserController do
  @moduledoc """
  A controller for inspecting the API key.
  """

  use PasswordlessWeb, :authenticated_api_controller
  use OpenApiSpex.ControllerSpecs

  alias Passwordless.App

  action_fallback PasswordlessWeb.FallbackController

  tags ["users"]
  security [%{}, %{"passwordless_auth" => ["read:users"]}]

  def show(%Plug.Conn{} = conn, %{"id" => id}, %App{} = app) do
    with {:ok, user} <- Passwordless.lookup_user(app, id) do
      render(conn, :get, user: user)
    end
  end
end
