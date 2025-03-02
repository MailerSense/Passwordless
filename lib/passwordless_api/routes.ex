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

        plug Hammer.Plug,
          rate_limit: {"api:authenticated", :timer.minutes(1), 300},
          when_nil: :raise,
          on_deny: &PasswordlessApi.Auth.handle_rate_limit_exceeded/2,
          by: {:conn, &PasswordlessApi.Auth.get_current_org_id/1}
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
