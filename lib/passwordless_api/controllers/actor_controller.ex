defmodule PasswordlessApi.ActorController do
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
    summary: "Get an actor",
    description: "Get an actor",
    responses: [
      ok: {"Action", "application/json", Schemas.Actor},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def get(%Plug.Conn{} = conn, %{"id" => id}, %App{} = app) do
    with {:ok, actor} <- Passwordless.lookup_actor(app, id) do
      render(conn, :get, actor: actor)
    end
  end
end
