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

  @client_id "x-passwordless-app-id"

  @doc """
  Authenticates API requests
  """
  def authenticate_client_api(%Plug.Conn{} = conn, _opts) do
    with ["app" <> _rest = app_id] <- get_req_header(conn, @client_id),
         %App{} = app <- Repo.get(App, app_id) do
      assign(conn, :current_app, app)
    else
      _ ->
        conn
        |> FallbackController.call({:error, :unauthorized})
        |> halt()
    end
  end

  @doc """
  Rate limits the API requests.
  """
  def rate_limit_api(conn, opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    key = "#{name}_#{get_current_org_id(conn)}"
    scale = Keyword.get(opts, :scale, :timer.minutes(1))
    limit = Keyword.get(opts, :limit, 200)

    case Passwordless.RateLimit.hit(key, scale, limit) do
      {:allow, _count} ->
        conn

      {:deny, retry_after} ->
        conn
        |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
        |> put_resp_header("x-rate-limit-domain", name)
        |> send_resp(429, [])
        |> halt()
    end
  end

  @doc """
  Fetches the current app id from the connection.
  """
  def get_current_app_id(%Plug.Conn{assigns: %{current_app: %App{id: app_id}}}) when is_binary(app_id), do: app_id
  def get_current_app_id(%Plug.Conn{}), do: nil

  @doc """
  Fetches the current org id from the connection.
  """
  def get_current_org_id(%Plug.Conn{assigns: %{current_app: %App{org_id: org_id}}}) when is_binary(org_id), do: org_id
  def get_current_org_id(%Plug.Conn{}), do: nil

  @doc """
  Fetches the current user ip from the connection.
  """
  def get_current_user_ip(%Plug.Conn{assigns: %{current_user_ip: current_user_ip}}) when is_binary(current_user_ip),
    do: current_user_ip

  def get_current_user_ip(%Plug.Conn{}), do: nil
end
