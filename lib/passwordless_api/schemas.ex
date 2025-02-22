defmodule PasswordlessApi.Schemas do
  @moduledoc """
  Schemas for the Passwordless API.
  """

  alias OpenApiSpex.Schema

  require OpenApiSpex

  defmodule AuthToken do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "AuthToken",
      description: "Response body for inspecting the API key",
      type: :object,
      properties: %{
        scopes: %Schema{
          type: :array,
          description: "API Scopes",
          enum: Passwordless.Security.Roles.auth_token_scopes(),
          example: [:sync]
        }
      },
      required: [:scopes],
      example: %{
        "scopes" => ["sync"]
      }
    })
  end
end
