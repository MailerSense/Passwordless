defmodule PasswordlessWeb.SiteMap do
  @moduledoc """
  Generates a sitemap
  """

  use PasswordlessWeb, :verified_routes

  def generate do
    static_routes = [
      ~p"/",
      ~p"/blog",
      ~p"/book-demo",
      ~p"/pricing",
      ~p"/contact",
      ~p"/product",
      ~p"/auth/sign-in",
      ~p"/auth/sign-up",
      ~p"/docs",
      ~p"/guides",
      ~p"/terms",
      ~p"/privacy",
      ~p"/active-development"
    ]

    Enum.map(static_routes, fn route ->
      %{loc: PasswordlessWeb.Endpoint.url() <> route, updated_at: DateTime.utc_now()}
    end)
  end
end
