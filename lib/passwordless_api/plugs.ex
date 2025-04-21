defmodule PasswordlessApi.Plugs do
  @moduledoc """
  A set of plugs related to user authentication.
  This module is imported into the router and thus any function can be called there as a plug.
  """

  use PasswordlessWeb, :verified_routes

  import Plug.Conn

  alias Passwordless.App
  alias Passwordless.AuthToken
  alias Passwordless.Repo
  alias PasswordlessWeb.FallbackController

  @doc """
  Authenticates API requests
  """
  def authenticate_api(%Plug.Conn{} = conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, query} <- AuthToken.get_app_by_token(token),
         %App{} = app <- Repo.one(query) do
      assign(conn, :current_app, app)
    else
      _ ->
        conn
        |> FallbackController.call({:error, :unauthorized})
        |> halt()
    end
  end

  @doc """
  Rate limits the API requests to 200 requests per minute.
  """
  def rate_limit_api(conn, _opts) do
    key = "api:" <> get_current_app_id(conn)
    scale = :timer.minutes(1)
    limit = 150

    case Passwordless.RateLimit.hit(key, scale, limit) do
      {:allow, _count} ->
        conn

      {:deny, retry_after} ->
        conn
        |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
        |> send_resp(429, [])
        |> halt()
    end
  end

  @doc """
  Fetches the current app id from the connection.
  """
  def get_current_app_id(%Plug.Conn{assigns: %{current_app: %App{id: app_id}}}) when is_binary(app_id), do: app_id
  def get_current_app_id(%Plug.Conn{}), do: nil
end
