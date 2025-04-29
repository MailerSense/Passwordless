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
        permissions: %Schema{
          type: :array,
          description: "API Permissions",
          enum: Passwordless.AuthToken.permissions(),
          example: [:actions]
        }
      },
      required: [:permissions],
      example: %{
        "permissions" => ["actions"]
      }
    })
  end
end
