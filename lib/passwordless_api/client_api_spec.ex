defmodule PasswordlessApi.ClientApiSpec do
  @moduledoc """
  The OpenAPI specification for the Passwordless API.
  """

  @behaviour OpenApiSpex.OpenApi

  alias OpenApiSpex.Components
  alias OpenApiSpex.Info
  alias OpenApiSpex.MediaType
  alias OpenApiSpex.OpenApi
  alias OpenApiSpex.Paths
  alias OpenApiSpex.Response
  alias OpenApiSpex.Schema
  alias OpenApiSpex.Tag
  alias PasswordlessWeb.Router

  @impl OpenApi
  def spec do
    open_api = %OpenApi{
      servers: [
        %OpenApiSpex.Server{url: "https://eu.passwordless.tools", description: "Production EU API"}
      ],
      info: %Info{
        title: "Passwordless Client API",
        version: "0.1.0"
      },
      components: %Components{
        responses: %{
          unauthorised: unauthorised_response(),
          forbidden: forbidden_response(),
          unprocessable_entity: unprocessable_entity_response(),
          no_content: no_content_response()
        }
      },
      tags: [%Tag{name: "server", description: "Server API"}],
      paths:
        Router
        |> Paths.from_router()
        |> Enum.filter(fn {path, _item} -> String.starts_with?(path, "/api/client") end)
        |> Map.new()
    }

    OpenApiSpex.resolve_schema_modules(open_api)
  end

  defp unauthorised_response do
    %Response{
      description: "Unauthorised",
      content: %{
        "application/json" => %MediaType{
          schema: %Schema{type: :object},
          example: %{error: "Unauthorised"}
        }
      }
    }
  end

  defp forbidden_response do
    %Response{
      description: "Forbidden",
      content: %{
        "application/json" => %MediaType{
          schema: %Schema{type: :object},
          example: %{error: "Forbidden"}
        }
      }
    }
  end

  defp unprocessable_entity_response do
    %Response{
      description: "Unprocessable Entity",
      content: %{
        "application/json" => %MediaType{
          schema: %Schema{type: :object},
          example: %{error: "Unprocessable Entity"}
        }
      }
    }
  end

  defp no_content_response do
    %Response{description: "No Content"}
  end
end
