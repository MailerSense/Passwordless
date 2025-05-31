defmodule PasswordlessApi.ActionTemplateController do
  @moduledoc """
  A controller for inspecting the API key.
  """

  use PasswordlessWeb, :authenticated_api_controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Reference
  alias Passwordless.App
  alias PasswordlessApi.Schemas

  action_fallback PasswordlessWeb.FallbackController

  tags ["actions"]
  security [%{}, %{"passwordless_auth" => ["write:action_templates", "read:action_templates"]}]

  operation :show,
    summary: "Show an action template",
    description: "Show an action template",
    parameters: [
      id: [in: :path, description: "Action Template ID", type: :string, example: "action_template_12345"]
    ],
    responses: [
      ok: {"ActionTemplate", "application/json", Schemas.ActionTemplate},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def show(%Plug.Conn{} = conn, %{"id" => id}, %App{} = app) do
    with {:ok, action_template} <- Passwordless.get_action_template_by_alias(app, id) do
      render(conn, :show, action_template: action_template)
    end
  end
end
