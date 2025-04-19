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
    decoded_params = decode_params(params)

    action = Repo.one(Action.preload_challenge(from(a in Action, prefix: ^Tenant.to_prefix(app), limit: 1)))

    render(conn, :authenticate, action: action)
  end

  def decode_params(%{"action" => action_name, "user" => %{"user_id" => user_id} = user, "rules" => rules}) do
    %{
      action: action_name,
      user: %{
        user_id: user_id,
        emails: decode_emails(user["emails"] || [])
      },
      rules: decode_rules(rules || [])
    }
  end

  defp decode_emails(emails) when is_list(emails) do
    Enum.map(emails, fn
      %{"address" => address, "primary" => primary} ->
        %{address: address, primary: primary}
    end)
  end

  defp decode_rules(rules) when is_list(rules) do
    Enum.map(rules, fn
      %{"if" => condition, "then" => then_actions} ->
        %{
          if: condition,
          then: Enum.map(then_actions, &decode_then_action/1)
        }
    end)
  end

  defp decode_then_action(%{"challenge" => kind}) do
    %{challenge: normalize_challenge(kind)}
  end

  defp normalize_challenge("email"), do: :email
  defp normalize_challenge("sms"), do: :sms
end
