defmodule PasswordlessWeb.Router do
  use PasswordlessWeb, :router

  import PasswordlessWeb.Plugs.Org
  import PasswordlessWeb.Plugs.ParseIP
  import PasswordlessWeb.Plugs.Project
  import PasswordlessWeb.UserAuth

  pipeline :browser do
    plug :parse_ip
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PasswordlessWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        ContentSecurityPolicy.serialize(
          struct(ContentSecurityPolicy.Policy, Passwordless.config(:content_security_policy))
        )
    }

    plug :fetch_current_user
    plug :fetch_active_user
    plug :fetch_impersonator_user

    plug PasswordlessWeb.Plugs.SetLocale, gettext: PasswordlessWeb.Gettext
    plug Hammer.Plug, rate_limit: {"browser:unauthenticated", :timer.minutes(1), 200}
  end

  pipeline :public_layout do
    plug :put_layout, html: {PasswordlessWeb.Layouts, :public}
  end

  pipeline :authenticated do
    plug :require_authenticated_user
    plug :require_onboarded_user
    plug :fetch_current_org
    plug :fetch_current_project
  end

  pipeline :authenticated_only do
    plug :require_authenticated_user
    plug :fetch_current_org
    plug :fetch_current_project
  end

  pipeline :public_browser do
    plug :parse_ip
    plug :accepts, ["html"]
    plug :put_root_layout, {PasswordlessWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        ContentSecurityPolicy.serialize(
          struct(ContentSecurityPolicy.Policy, Passwordless.config(:content_security_policy))
        )
    }
  end

  # Public routes
  scope "/", PasswordlessWeb do
    pipe_through [:browser, :public_layout]

    # Add public controller routes here
    get "/", PageController, :landing_page
    get "/docs", PageController, :docs
    get "/guides", PageController, :guides
    get "/terms", PageController, :terms
    get "/privacy", PageController, :privacy
    get "/sitemap.xml", SitemapController, :index

    # Contact
    post "/contact/submit-form", ContactController, :submit_form
  end

  scope "/app", PasswordlessWeb do
    pipe_through [:browser, :authenticated_only]

    # Accept invitation to the organization
    post "/invitation/accept", OrgController, :accept_invitation
  end

  # App routes - for signed in and confirmed users only
  scope "/app", PasswordlessWeb do
    pipe_through [:browser, :authenticated]

    # User email/password actions
    put "/user/settings/update-password", UserSettingsController, :update_password
    get "/user/settings/confirm-email/:token", UserSettingsController, :confirm_email

    # User TOTP validation
    get "/user/totp", UserTOTPController, :new
    post "/user/totp", UserTOTPController, :create

    # Organization switcher
    post "/org/switch", OrgController, :switch

    # Project switcher
    post "/project/switch", ProjectController, :switch

    # Billing
    get "/billing/checkout/:plan_id", BillingController, :checkout

    live_session :app_onboarding_session,
      on_mount: [
        {PasswordlessWeb.User.Hooks, :require_authenticated_user},
        {PasswordlessWeb.Org.Hooks, :fetch_current_org},
        {PasswordlessWeb.Project.Hooks, :fetch_current_project}
      ] do
      live "/onboarding", User.OnboardingLive
    end

    live_session :app_session,
      on_mount: [
        {PasswordlessWeb.User.Hooks, :require_authenticated_user},
        {PasswordlessWeb.Org.Hooks, :fetch_current_org},
        {PasswordlessWeb.Org.Hooks, :require_current_org},
        {PasswordlessWeb.Project.Hooks, :fetch_current_project}
      ] do
      # Home
      live "/home", App.HomeLive.Index, :index

      # Users
      live "/users", App.ActorLive.Index, :index
      live "/users/new", App.ActorLive.Index, :new
      live "/users/import", App.ActorLive.Index, :import
      live "/users/:id/edit", App.ActorLive.Index, :edit
      live "/users/:id/delete", App.ActorLive.Index, :delete

      # Methods
      live "/methods", App.MethodLive.Index, :index

      # Reports
      live "/reports", App.ReportLive.Index, :index

      # Integrations
      live "/integrations", App.IntegrationLive.Index, :index

      # Team
      live "/members", App.MemberLive.Index, :index
      live "/members/invite", App.MemberLive.Index, :invite
      live "/members/invitations", App.MemberLive.Index, :invitations
      live "/members/:id/edit", App.MemberLive.Index, :edit
      live "/members/:id/delete", App.MemberLive.Index, :delete

      # Project
      live "/projects", App.ProjectLive.Index, :index
      live "/projects/new", App.ProjectLive.Index, :new
      live "/projects/:id/edit", App.ProjectLive.Index, :edit
      live "/projects/:id/delete", App.ProjectLive.Index, :delete

      # Billing
      live "/billing", App.BillingLive.Index, :index
      live "/subscribe/success", App.BillingLive.SubscribeSuccessLive, :index
      live "/subscribe", App.BillingLive.SubscribeLive, :index

      # Settings
      live "/settings", User.ProfileLive

      # User
      live "/edit-email", User.ProfileLive, :change_email
      live "/password", User.PasswordLive, :index
      live "/password/change", User.PasswordLive, :change
      live "/invitations", User.InvitationsLive
      live "/security", User.SecurityLive

      # Org
      live "/organization", Org.EditLive, :index
      live "/organization/new", Org.EditLive, :new

      # Org
      live "/project", App.ProjectLive.Index, :index
      live "/project/new", App.ProjectLive.Index, :new

      # API Keys
      live "/auth-tokens", Org.AuthTokenLive.Index, :index
      live "/auth-tokens/new", Org.AuthTokenLive.Index, :new
      live "/auth-tokens/revoked", Org.AuthTokenLive.Index, :revoked
      live "/auth-tokens/:id", Org.AuthTokenLive.Index, :edit
      live "/auth-tokens/:id/revoke", Org.AuthTokenLive.Index, :revoke
      live "/auth-tokens/:id/reveal", Org.AuthTokenLive.Index, :reveal

      # Knowledge
      live "/blog", Knowledge.BlogLive, :index
      live "/docs", Knowledge.DocLive, :index
      live "/guides", Knowledge.GuideLive, :index
    end
  end

  scope "/" do
    use PasswordlessApi.Routes
    use PasswordlessWeb.AuthRoutes
    use PasswordlessWeb.AdminRoutes
    use PasswordlessWeb.DevRoutes
  end
end
