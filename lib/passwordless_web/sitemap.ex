defmodule PasswordlessWeb.SiteMap do
  @moduledoc """
  Generates a sitemap
  """

  use PasswordlessWeb, :verified_routes

  def generate do
    static_routes = [
      ~p"/",
      ~p"/auth/sign-in",
      ~p"/auth/sign-up"
    ]

    Enum.map(static_routes, fn route ->
      %{loc: PasswordlessWeb.Endpoint.url() <> route, updated_at: DateTime.utc_now()}
    end)
  end
end
