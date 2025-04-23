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

  def get(%Plug.Conn{} = conn, %{"id" => id}, %App{} = app) do
    with {:ok, action} <- Passwordless.get_action(app, id) do
      action =
        Repo.preload(
          action,
          [:rule, {:actor, [:totps, :email, :emails, :phone, :phones]}, {:challenge, [:email_message]}, :events]
        )

      render(conn, :get, action: action)
    end
  end

  def authenticate(%Plug.Conn{} = conn, params, %App{} = app) do
    actor_params = Map.get(params, "user")

    action_params = %{
      name: Map.get(params, "action")
    }

    challenge_params = %{
      kind: :email_otp,
      state: Challenge.starting_state!(:email_otp),
      current: true
    }

    {:ok, action} =
      Repo.transact(fn ->
        with {:ok, rule} <- Passwordless.create_rule(app, %{conditions: %{}, effects: %{}}),
             {:ok, actor} <- Passwordless.resolve_actor(app, actor_params),
             {:ok, action} <- Passwordless.create_action(app, actor, Map.put(action_params, :rule_id, rule.id)),
             {:ok, challenge} <- Passwordless.create_challenge(app, action, challenge_params),
             do: Passwordless.handle_challenge(app, actor, action, challenge, "send_otp", %{email: actor.email})
      end)

    PasswordlessWeb.Endpoint.broadcast(Action.topic_for(app), "inserted", action)

    render(conn, :authenticate, action: action)
  end

  def continue(%Plug.Conn{} = conn, params, %App{} = app) do
    render(conn, :continue, action: nil)
  end
end
