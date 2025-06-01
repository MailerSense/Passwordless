defmodule PasswordlessApi.ActionController do
  @moduledoc """
  A controller for inspecting the API key.
  """

  use PasswordlessWeb, :authenticated_api_controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Reference
  alias Passwordless.Action
  alias Passwordless.App
  alias Passwordless.Challenge
  alias Passwordless.Repo
  alias PasswordlessApi.Schemas

  action_fallback PasswordlessWeb.FallbackController

  tags ["actions"]
  security [%{}, %{"passwordless_auth" => ["write:actions", "read:actions"]}]

  defmodule AuthenticateAction do
    @moduledoc false
    use Drops.Contract

    schema(atomize: true) do
      %{
        required(:action) => string(:filled?),
        required(:user) => %{
          optional(:username) => string(:filled?),
          optional(:emails) =>
            list(%{
              required(:address) => string(:filled?),
              optional(:primary) => boolean()
            }),
          optional(:data) => map(:string)
        },
        optional(:track) => %{
          optional(:device_id) => string(:filled?),
          optional(:user_agent) => string(:filled?),
          optional(:ip_address) => string(:filled?)
        },
        required(:rules) =>
          list(%{
            required(:if) => any(),
            required(:then) => list(any())
          })
      }
    end
  end

  operation :new,
    summary: "Authenticate an action",
    description: "Authenticate an action",
    responses: [
      ok: {"Action", "application/json", Schemas.Action},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def new(%Plug.Conn{} = conn, params, %App{} = app) do
    with {:ok, decoded} <- AuthenticateAction.conform(params) do
      user_params = decoded[:user]

      action_params = %{
        name: decoded[:action]
      }

      challenge_params = %{
        kind: :email_otp,
        state: Challenge.starting_state!(:email_otp),
        current: true
      }

      event_params = fn old_action, new_action ->
        %{
          event: "send_otp",
          user_agent: get_in(decoded, [:track, :user_agent]),
          ip_address: get_in(decoded, [:track, :ip_address]),
          metadata: %{
            before: %{
              name: old_action.name,
              state: old_action.state
            },
            after: %{
              name: new_action.name,
              state: new_action.state
            },
            attrs: %{}
          }
        }
      end

      result =
        Repo.transact(fn ->
          with {:ok, user} <- Passwordless.resolve_user(app, user_params),
               {:ok, action} <- Passwordless.create_action(app, user, action_params),
               {:ok, challenge} <- Passwordless.create_challenge(app, action, challenge_params),
               {:ok, new_action} <-
                 Passwordless.handle_challenge(app, user, action, challenge, "send_otp", %{email: user.email}),
               {:ok, event} <- Passwordless.create_event(app, action, event_params.(action, new_action)),
               do: {:ok, new_action}
        end)

      with {:ok, action} <- result do
        PasswordlessWeb.Endpoint.broadcast(Action.topic_for(app), "inserted", action)
        render(conn, :authenticate, action: action)
      end
    end
  end

  operation :show,
    summary: "Show an action",
    description: "Show an action",
    parameters: [
      id: [in: :path, description: "Action ID", type: :string, example: "action_12345"]
    ],
    responses: [
      ok: {"Action", "application/json", Schemas.Action},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def show(%Plug.Conn{} = conn, %{"id" => id}, %App{} = app) do
    with {:ok, action} <- Passwordless.get_action(app, id) do
      render(conn, :show, action: action)
    end
  end

  operation :update,
    summary: "Update an action",
    description: "Update an action",
    parameters: [
      id: [in: :path, description: "Action ID", type: :string, example: "action_12345"]
    ],
    responses: [
      ok: {"Action", "application/json", Schemas.Action},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  def update(%Plug.Conn{} = conn, %{"id" => id}, %App{} = app) do
    {:error, :not_implemented}
  end
end
