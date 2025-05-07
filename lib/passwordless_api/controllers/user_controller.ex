defmodule PasswordlessApi.UserController do
  @moduledoc """
  A controller for inspecting the API key.
  """

  use PasswordlessWeb, :authenticated_api_controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Reference
  alias Passwordless.App
  alias PasswordlessApi.Schemas

  action_fallback PasswordlessWeb.FallbackController

  operation :show,
    summary: "Get a user",
    description: "Get a user",
    responses: [
      ok: {"User", "application/json", Schemas.User},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def get(%Plug.Conn{} = conn, %{"id" => id}, %App{} = app) do
    with {:ok, user} <- Passwordless.lookup_user(app, id) do
      render(conn, :get, user: user)
    end
  end
end
