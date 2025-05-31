defmodule PasswordlessApi.AppClientController do
  @moduledoc """
  A controller for inspecting the API key.
  """

  use PasswordlessWeb, :authenticated_api_controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Reference
  alias Passwordless.App
  alias PasswordlessApi.Schemas

  action_fallback PasswordlessWeb.FallbackController

  tags ["apps"]
  security [%{}, %{"passwordless_auth" => ["read:apps"]}]

  operation :index,
    summary: "Show App",
    description: "Show the properties of the current App",
    responses: [
      ok: {"App", "application/json", Schemas.App},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def index(%Plug.Conn{} = conn, _params, %App{} = app) do
    render(conn, :index, app: app)
  end
end
