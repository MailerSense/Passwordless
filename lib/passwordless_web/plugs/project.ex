defmodule PasswordlessWeb.Plugs.Project do
  @moduledoc false
  use PasswordlessWeb, :verified_routes

  import Plug.Conn

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Org
  alias Passwordless.Project

  @project_key "project_id"

  def fetch_current_project(%Plug.Conn{} = conn, _opts) do
    case {conn.assigns[:current_user], conn.assigns[:current_org]} do
      {%User{} = user, %Org{} = org} ->
        case load_project(org, get_session(conn, @project_key)) do
          %Project{} = project ->
            conn
            |> assign(:current_project, project)
            |> assign(:current_user, %User{user | current_project: project})
            |> put_session(@project_key, project.id)

          _ ->
            conn
        end

      _ ->
        conn
    end
  end

  # Private

  defp load_project(%Org{} = org, project_id) when is_binary(project_id) do
    case Passwordless.get_project(org, project_id) do
      %Project{} = project -> project
      _ -> load_project(org, nil)
    end
  end

  defp load_project(%Org{} = org, _project_id) do
    case Organizations.preload_projects(org) do
      %Org{projects: [%Project{} = project | _]} -> project
      _ -> nil
    end
  end
end
