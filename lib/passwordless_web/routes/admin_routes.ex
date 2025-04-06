defmodule PasswordlessWeb.AdminRoutes do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      import Backpex.Router
      # import Oban.Web.Router
      import PasswordlessWeb.UserAuth
      import Phoenix.LiveDashboard.Router

      pipeline :admin do
        plug :require_admin_user
        plug Backpex.ThemeSelectorPlug
      end

      scope "/admin", PasswordlessWeb do
        pipe_through [:browser, :require_authenticated_user]

        delete "/impersonate", UserImpersonationController, :delete
      end

      scope "/admin", PasswordlessWeb do
        pipe_through [:browser, :authenticated, :admin]

        backpex_routes()

        live_dashboard("/live", metrics: PasswordlessWeb.Telemetry, ecto_repos: [Passwordless.Repo])
        # oban_dashboard("/oban", resolver: PasswordlessWeb.ObanResolver)

        get "/impersonate/:user_id", UserImpersonationController, :create

        live_session :admin_session,
          on_mount: [
            {Backpex.InitAssigns, :default},
            {PasswordlessWeb.User.Hooks, :require_authenticated_user},
            {PasswordlessWeb.Org.Hooks, :fetch_current_org}
          ] do
          # Admin
          live_resources "/orgs", Admin.OrgLive
          live_resources "/users", Admin.UserLive
          live_resources "/tokens", Admin.TokenLive
          live_resources "/memberships", Admin.MembershipLive
          live_resources "/credentials", Admin.CredentialLive

          # Activity
          live "/activity", Admin.ActivityLive.Index, :index
        end
      end
    end
  end
end
