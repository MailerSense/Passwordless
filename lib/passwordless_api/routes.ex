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
        plug :rate_limit_api
      end

      pipeline :api_idempotent do
        plug OneAndDone.Plug, cache: Passwordless.Cache
      end

      scope "/api" do
        pipe_through :api

        get "/openapi", OpenApiSpex.Plug.RenderSpec, []
      end

      scope "/api/v1", PasswordlessApi do
        pipe_through [:api, :api_authenticated]

        scope "/actions" do
          pipe_through :api_idempotent

          post "/authenticate", ActionController, :authenticate
        end

        scope "/users" do
          get "/:id", ActorController, :get
        end
      end
    end
  end
end
