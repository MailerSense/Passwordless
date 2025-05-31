defmodule PasswordlessApi.AuthTokenController do
  @moduledoc """
  A controller for inspecting the API key.
  """

  use PasswordlessWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Reference
  alias PasswordlessApi.Schemas

  action_fallback PasswordlessWeb.FallbackController

  tags ["auth"]
  security [%{}, %{"passwordless_auth" => ["read:auth_tokens"]}]

  operation :inspect_auth_token,
    summary: "Inspect API key",
    description: "Inspect the properties of the current API key",
    responses: [
      ok: {"Auth Token", "application/json", Schemas.AuthToken},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def inspect_auth_token(%Plug.Conn{} = conn, _params) do
    render(conn, :show, auth_token: conn.assigns.current_auth_token)
  end
end
