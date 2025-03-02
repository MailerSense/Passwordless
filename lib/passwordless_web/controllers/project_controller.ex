defmodule PasswordlessWeb.ProjectController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.Org

  @app_key "app_id"

  def switch(conn, %{"app_id" => app_id}, %User{current_org: %Org{} = org}) do
    app = Passwordless.get_app!(org, app_id)

    conn
    |> assign(:current_app, app)
    |> put_session(@app_key, app.id)
    |> redirect(to: ~p"/app/home")
  end
end
