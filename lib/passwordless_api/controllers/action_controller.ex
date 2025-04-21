defmodule PasswordlessApi.ActionController do
  @moduledoc """
  A controller for inspecting the API key.
  """

  use PasswordlessWeb, :authenticated_api_controller
  use OpenApiSpex.ControllerSpecs

  import Ecto.Query

  alias Database.Tenant
  alias OpenApiSpex.Reference
  alias Passwordless.Action
  alias Passwordless.App
  alias Passwordless.Repo
  alias PasswordlessApi.Schemas

  action_fallback PasswordlessWeb.FallbackController

  operation :authenticate,
    summary: "Authenticate an action",
    description: "Authenticate an action",
    responses: [
      ok: {"Action", "application/json", Schemas.Action},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def authenticate(%Plug.Conn{} = conn, params, %App{} = app) do
    with {:ok, actor} <- Passwordless.resolve_actor(app, params["user"]) do
      action = Repo.one(Action.preload_challenge(from(a in Action, prefix: ^Tenant.to_prefix(app), limit: 1)))
      render(conn, :authenticate, action: action)
    end
  end
end
