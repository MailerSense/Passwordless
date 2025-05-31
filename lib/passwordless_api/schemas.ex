defmodule PasswordlessApi.Schemas do
  @moduledoc """
  Schemas for the Passwordless API.
  """

  alias OpenApiSpex.Schema

  require OpenApiSpex

  defmodule App do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "App",
      description: "A passwordless application tenant",
      type: :object,
      properties: %{
        id: %Schema{
          type: :string,
          description: "The unique identifier for the action",
          example: "action_12345"
        },
        name: %Schema{
          type: :string,
          description: "The name of the application",
          example: "My Passwordless App"
        },
        state: %Schema{
          type: :string,
          description: "The current state of the app",
          enum: Passwordless.App.states(),
          example: "pending"
        },
        inserted_at: %Schema{
          type: :string,
          format: "date-time",
          description: "The timestamp when the app was created",
          example: "2023-10-01T12:00:00Z"
        },
        updated_at: %Schema{
          type: :string,
          format: "date-time",
          description: "The timestamp when the app was last updated",
          example: "2023-10-01T12:00:00Z"
        }
      },
      required: [:id, :name, :state, :inserted_at, :updated_at],
      example: %{
        "id" => "app_12345",
        "name" => "My Passwordless App",
        "state" => "active",
        "inserted_at" => "2023-10-01T12:00:00Z",
        "updated_at" => "2023-10-01T12:00:00Z"
      }
    })
  end

  defmodule Action do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "Action",
      description: "An authenticated action",
      type: :object,
      properties: %{
        id: %Schema{
          type: :string,
          description: "The unique identifier for the action",
          example: "action_12345"
        },
        data: %Schema{
          type: :object,
          description: "Additional data associated with the action",
          example: %{"key" => "value"}
        },
        state: %Schema{
          type: :string,
          description: "The current state of the action",
          enum: Passwordless.Action.states(),
          example: "pending"
        },
        # challenge: %Reference{"$ref": "#/components/schemas/Challenge"},
        inserted_at: %Schema{
          type: :string,
          format: "date-time",
          description: "The timestamp when the action was created",
          example: "2023-10-01T12:00:00Z"
        },
        updated_at: %Schema{
          type: :string,
          format: "date-time",
          description: "The timestamp when the action was last updated",
          example: "2023-10-01T12:00:00Z"
        }
      },
      required: [:id, :data, :state, :inserted_at, :updated_at],
      example: %{
        "id" => "action_12345",
        "data" => %{"key" => "value"},
        "state" => "pending",
        "inserted_at" => "2023-10-01T12:00:00Z",
        "updated_at" => "2023-10-01T12:00:00Z"
      }
    })
  end

  defmodule ActionTemplate do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "ActionTemplate",
      description: "An template for a action-based authentication flow",
      type: :object,
      properties: %{
        id: %Schema{
          type: :string,
          description: "The unique identifier for the action",
          example: "action_12345"
        },
        inserted_at: %Schema{
          type: :string,
          format: "date-time",
          description: "The timestamp when the action was created",
          example: "2023-10-01T12:00:00Z"
        },
        updated_at: %Schema{
          type: :string,
          format: "date-time",
          description: "The timestamp when the action was last updated",
          example: "2023-10-01T12:00:00Z"
        }
      },
      required: [:id, :inserted_at, :updated_at],
      example: %{
        "id" => "action_template_12345",
        "inserted_at" => "2023-10-01T12:00:00Z",
        "updated_at" => "2023-10-01T12:00:00Z"
      }
    })
  end

  defmodule Challenge do
    @moduledoc false
    OpenApiSpex.schema(%{
      title: "Challenge",
      description: "An authenticated challenge",
      type: :object,
      properties: %{
        id: %Schema{
          type: :string,
          description: "The unique identifier for the challenge",
          example: "challenge_12345"
        },
        kind: %Schema{
          type: :string,
          description: "The kind of challenge",
          enum: Passwordless.Challenge.kinds(),
          example: "email_otp"
        },
        state: %Schema{
          type: :string,
          description: "The current state of the challenge",
          enum: Passwordless.Challenge.states(),
          example: "otp_sent"
        },
        inserted_at: %Schema{
          type: :string,
          format: "date-time",
          description: "The timestamp when the challenge was created",
          example: "2023-10-01T12:00:00Z"
        },
        updated_at: %Schema{
          type: :string,
          format: "date-time",
          description: "The timestamp when the challenge was last updated",
          example: "2023-10-01T12:00:00Z"
        }
      },
      required: [:id, :kind, :state, :inserted_at, :updated_at],
      example: %{
        "id" => "challenge_12345",
        "kind" => "email_otp",
        "state" => "otp_sent",
        "inserted_at" => "2023-10-01T12:00:00Z",
        "updated_at" => "2023-10-01T12:00:00Z"
      }
    })
  end

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
