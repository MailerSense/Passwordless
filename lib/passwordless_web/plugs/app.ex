defmodule PasswordlessWeb.Plugs.App do
  @moduledoc false
  use PasswordlessWeb, :verified_routes

  import Plug.Conn

  alias Passwordless.Accounts.User
  alias Passwordless.App
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Org
  alias Passwordless.Repo

  @app_key "app_id"

  def fetch_current_app(%Plug.Conn{} = conn, _opts) do
    case {conn.assigns[:current_user], conn.assigns[:current_org]} do
      {%User{} = user, %Org{} = org} ->
        case load_app(org, get_session(conn, @app_key)) do
          %App{} = app ->
            Repo.put_tenant_id(app)

            conn
            |> assign(:current_app, app)
            |> assign(:current_user, %User{user | current_app: app})
            |> put_session(@app_key, app.id)

          _ ->
            conn
        end

      _ ->
        conn
    end
  end

  # Private

  defp load_app(%Org{} = org, app_id) when is_binary(app_id) do
    case Passwordless.get_app(org, app_id) do
      %App{} = app -> app
      _ -> load_app(org, nil)
    end
  end

  defp load_app(%Org{} = org, _app_id) do
    case Organizations.preload_apps(org) do
      %Org{apps: [%App{} = app | _]} -> app
      _ -> nil
    end
  end
end
