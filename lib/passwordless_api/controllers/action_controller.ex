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

  operation :authenticate,
    summary: "Authenticate an action",
    description: "Authenticate an action",
    responses: [
      ok: {"Action", "application/json", Schemas.Action},
      unauthorized: %Reference{"$ref": "#/components/responses/unauthorised"}
    ]

  defmodule AuthenticateAction do
    @moduledoc false
    use Drops.Contract

    schema(atomize: true) do
      %{
        required(:action) => string(:filled?),
        required(:actor) => %{
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
            required(:if) => boolean(),
            required(:then) => list(:string)
          })
      }
    end
  end

  defmodule ContinueAction do
    @moduledoc false
    use Drops.Contract

    schema(atomize: true) do
      %{
        required(:action) => string(:filled?),
        required(:data) => %{
          optional(:code) => string(:filled?)
        },
        optional(:track) => %{
          optional(:device_id) => string(:filled?),
          optional(:user_agent) => string(:filled?),
          optional(:ip_address) => string(:filled?)
        }
      }
    end
  end

  def get(%Plug.Conn{} = conn, %{"id" => id}, %App{} = app) do
    with {:ok, action} <- Passwordless.get_action(app, id) do
      render(conn, :get, action: action)
    end
  end

  def authenticate(%Plug.Conn{} = conn, params, %App{} = app) do
    with {:ok, decoded} <- AuthenticateAction.conform(params) do
      actor_params = decoded[:actor]

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
          with {:ok, rule} <- Passwordless.create_rule(app, %{conditions: %{}, effects: %{}}),
               {:ok, actor} <- Passwordless.resolve_actor(app, actor_params),
               {:ok, action} <- Passwordless.create_action(app, actor, Map.put(action_params, :rule_id, rule.id)),
               {:ok, challenge} <- Passwordless.create_challenge(app, action, challenge_params),
               {:ok, new_action} <-
                 Passwordless.handle_challenge(app, actor, action, challenge, "send_otp", %{email: actor.email}),
               {:ok, event} <- Passwordless.create_event(app, action, event_params.(action, new_action)),
               {:ok, _event_or_job} <- Passwordless.locate_action_event(app, event),
               do: {:ok, new_action}
        end)

      with {:ok, action} <- result do
        PasswordlessWeb.Endpoint.broadcast(Action.topic_for(app), "inserted", action)
        render(conn, :authenticate, action: action)
      end
    end
  end

  def continue(%Plug.Conn{} = conn, params, %App{} = app) do
    render(conn, :continue, action: nil)
  end
end
