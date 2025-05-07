defmodule PasswordlessApi.Routes do
  @moduledoc """
  The API routes for the Passwordless API.
  """

  defmacro __using__(_) do
    quote do
      import PasswordlessApi.Plugs

      pipeline :api do
        plug :accepts, ["json"]
        plug OpenApiSpex.Plug.PutApiSpec, module: PasswordlessApi.ApiSpec
      end

      pipeline :api_authenticated do
        plug :authenticate_api
      end

      pipeline :api_rate_limited do
        plug :rate_limit_api, name: "general", limit: 200
      end

      pipeline :api_rate_limited_actions do
        plug :rate_limit_api, name: "actions", limit: 100
      end

      pipeline :api_idempotent do
        plug OneAndDone.Plug, cache: Passwordless.Cache
      end

      scope "/api" do
        pipe_through :api

        get "/openapi", OpenApiSpex.Plug.RenderSpec, []
      end

      scope "/api/v1", PasswordlessApi do
        pipe_through [
          :api,
          :api_authenticated,
          :api_rate_limited
        ]

        scope "/app" do
          get "/", AppController, :show
          get "/authenticators", AppController, :authenticators
        end

        scope "/actors" do
          get "/:id", UserController, :get
        end

        scope "/actions" do
          get "/:id", ActionController, :get

          scope "/" do
            pipe_through [
              :api_rate_limited_actions,
              :api_idempotent
            ]

            post "/authenticate", ActionController, :authenticate
          end
        end
      end
    end
  end
end
