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
        plug :rate_limit_api, name: "general"
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

        scope "/actions" do
          get "/:id", ActionController, :get

          scope "/" do
            pipe_through [
              :api_rate_limited_actions,
              :api_idempotent
            ]

            post "/authenticate", ActionController, :authenticate
            post "/continue", ActionController, :continue
          end
        end

        scope "/actors" do
          get "/:id", ActorController, :get
        end
      end
    end
  end
end
