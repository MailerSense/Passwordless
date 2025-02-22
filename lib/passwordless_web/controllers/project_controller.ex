defmodule PasswordlessWeb.ProjectController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.Org

  @project_key "project_id"

  def switch(conn, %{"project_id" => project_id}, %User{current_org: %Org{} = org}) do
    project = Passwordless.get_project!(org, project_id)

    conn
    |> assign(:current_project, project)
    |> put_session(@project_key, project.id)
    |> redirect(to: ~p"/app/home")
  end
end
