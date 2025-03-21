defmodule PasswordlessApi.Auth do
  @moduledoc """
  A set of plugs related to user authentication.
  This module is imported into the router and thus any function can be called there as a plug.
  """

  use PasswordlessWeb, :verified_routes

  import Plug.Conn

  alias Passwordless.AuthToken
  alias Passwordless.Organizations.Org
  alias Passwordless.Repo
  alias PasswordlessWeb.FallbackController

  @doc """
  Fetches the org by API key
  """
  def fetch_org(%Plug.Conn{} = conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, query} <- AuthToken.get_org_and_key(token),
         {%Org{} = org, %AuthToken{} = token} <- Repo.one(query) do
      conn
      |> assign(:current_org, org)
      |> assign(:current_auth_token, token)
    else
      _ ->
        conn
        |> FallbackController.call({:error, :unauthorized})
        |> halt()
    end
  end

  @doc """
  Checks if the current API key has access to the given scopes.
  """
  def scope_access(%Plug.Conn{} = conn, scopes \\ []) do
    case conn.assigns[:current_auth_token] do
      %AuthToken{} = auth_token ->
        if AuthToken.can?(auth_token, scopes),
          do: conn,
          else:
            conn
            |> FallbackController.call({:error, :forbidden})
            |> halt()

      _ ->
        conn
        |> FallbackController.call({:error, :unauthorized})
        |> halt()
    end
  end

  @doc """
  Fetches the current org id from the connection.
  """
  def get_current_org_id(%Plug.Conn{assigns: %{current_org: %Org{id: org_id}}}) when is_binary(org_id), do: org_id
  def get_current_org_id(%Plug.Conn{}), do: nil

  @doc """
  Handles a rate limit deny.
  """
  def handle_rate_limit_exceeded(%Plug.Conn{} = conn, _opts) do
    conn
    |> FallbackController.call({:error, :rate_limit_exceeded})
    |> halt()
  end
end
