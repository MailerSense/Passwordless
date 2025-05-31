defmodule PasswordlessApi.Routes do
  @moduledoc """
  The API routes for the Passwordless API.
  """

  defmacro __using__(_) do
    quote do
      import PasswordlessApi.Plugs

      pipeline :api_server do
        plug :parse_ip
        plug :accepts, ["json"]
        plug OpenApiSpex.Plug.PutApiSpec, module: PasswordlessApi.ServerApiSpec
      end

      pipeline :api_client do
        plug :parse_ip
        plug :accepts, ["json"]
        plug OpenApiSpex.Plug.PutApiSpec, module: PasswordlessApi.ClientApiSpec
      end

      pipeline :api_authenticated do
        plug :authenticate_api
      end

      pipeline :api_authenticated_client do
        plug :authenticate_client_api
      end

      pipeline :api_rate_limited_client do
        plug :rate_limit_api, name: "client", limit: 60
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

      scope "/api/client" do
        pipe_through :api_client

        get "/openapi", OpenApiSpex.Plug.RenderSpec, []
      end

      scope "/api/server" do
        pipe_through :api_server

        get "/openapi", OpenApiSpex.Plug.RenderSpec, []
      end

      scope "/api/client/v1", PasswordlessApi do
        pipe_through [
          :api_client,
          :api_authenticated_client,
          :api_rate_limited_client
        ]

        resources "/app", AppClientController, only: [:index]
        resources "/action-templates", ActionTemplateController, only: [:show]

        scope "/actions" do
          pipe_through [
            :api_rate_limited_actions,
            :api_idempotent
          ]
        end
      end

      scope "/api/server/v1", PasswordlessApi do
        pipe_through [
          :api_server,
          :api_authenticated,
          :api_rate_limited
        ]

        scope "/app" do
          get "/", AppController, :show
          get "/authenticators", AppController, :authenticators
        end

        scope "/users" do
          get "/:id", UserController, :get
        end

        resources "/actions", ActionController, only: [:show]

        scope "/actions" do
          pipe_through [
            :api_rate_limited_actions,
            :api_idempotent
          ]

          post "/query", ActionController, :query
          post "/authenticate", ActionController, :authenticate
        end
      end
    end
  end
end
