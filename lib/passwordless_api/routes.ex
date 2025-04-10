defmodule PasswordlessApi.Routes do
  @moduledoc """
  The API routes for the Passwordless API.
  """

  defmacro __using__(_) do
    quote do
      import PasswordlessApi.Auth

      pipeline :api do
        plug :accepts, ["json"]
        plug OpenApiSpex.Plug.PutApiSpec, module: PasswordlessApi.ApiSpec
      end

      pipeline :api_authenticated do
        plug :fetch_org
        plug :rate_limit_api

        plug OneAndDone.Plug, cache: Cache
      end

      scope "/api" do
        pipe_through :api

        get "/openapi", OpenApiSpex.Plug.RenderSpec, []
      end

      scope "/api/v1", PasswordlessApi do
        pipe_through [:api, :api_authenticated]
      end
    end
  end
end
