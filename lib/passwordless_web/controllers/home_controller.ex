defmodule PasswordlessWeb.HomeController do
  use PasswordlessWeb, :authenticated_controller

  def index(conn, _params, user) do
    redirect(conn, to: PasswordlessWeb.Helpers.home_path(user))
  end
end
