defmodule PasswordlessWeb.Router do
  use PasswordlessWeb, :router

  import PasswordlessWeb.Plugs.App
  import PasswordlessWeb.Plugs.Org
  import PasswordlessWeb.Plugs.ParseIP
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
    plug :fetch_current_app
  end

  pipeline :authenticated_only do
    plug :require_authenticated_user
    plug :fetch_current_org
    plug :fetch_current_app
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
    post "/apps/switch", ProjectController, :switch

    # Billing
    get "/billing/checkout/:plan_id", BillingController, :checkout

    # DNS
    get "/domain/dns/download", DNSController, :download

    live_session :app_onboarding_session,
      on_mount: [
        {PasswordlessWeb.User.Hooks, :require_authenticated_user},
        {PasswordlessWeb.Org.Hooks, :fetch_current_org},
        {PasswordlessWeb.App.Hooks, :fetch_current_app}
      ] do
      live "/onboarding", User.OnboardingLive
    end

    live_session :app_session,
      on_mount: [
        {PasswordlessWeb.User.Hooks, :require_authenticated_user},
        {PasswordlessWeb.Org.Hooks, :fetch_current_org},
        {PasswordlessWeb.Org.Hooks, :require_current_org},
        {PasswordlessWeb.App.Hooks, :fetch_current_app}
      ] do
      # Home
      live "/home", App.HomeLive.Index, :index

      # Users
      live "/users", App.ActorLive.Index, :index
      live "/users/new", App.ActorLive.Index, :new
      live "/users/import", App.ActorLive.Index, :import
      live "/users/:id/edit", App.ActorLive.Edit, :edit
      live "/users/:id/edit/delete", App.ActorLive.Edit, :delete
      live "/users/:id/edit/email/new", App.ActorLive.Edit, :new_email
      live "/users/:id/edit/email/:email_id/edit", App.ActorLive.Edit, :edit_email
      live "/users/:id/edit/email/:email_id/delete", App.ActorLive.Edit, :delete_email
      live "/users/:id/edit/phone/new", App.ActorLive.Edit, :new_phone
      live "/users/:id/edit/phone/:phone_id/edit", App.ActorLive.Edit, :edit_phone
      live "/users/:id/edit/phone/:phone_id/delete", App.ActorLive.Edit, :delete_phone
      live "/users/:id/edit/identity/new", App.ActorLive.Edit, :new_identity
      live "/users/:id/edit/identity/:identity_id/edit", App.ActorLive.Edit, :edit_identity
      live "/users/:id/edit/identity/:identity_id/delete", App.ActorLive.Edit, :delete_identity
      live "/users/:id/delete", App.ActorLive.Index, :delete

      # Methods
      live "/methods/magic-link", App.MethodLive.Index, :magic_link
      live "/methods/sms", App.MethodLive.Index, :sms
      live "/methods/email", App.MethodLive.Index, :email
      live "/methods/authenticator", App.MethodLive.Index, :authenticator
      live "/methods/security-key", App.MethodLive.Index, :security_key
      live "/methods/passkey", App.MethodLive.Index, :passkey
      live "/methods/recovery-codes", App.MethodLive.Index, :recovery_codes

      # Email
      live "/emails/:id/:language/edit", App.EmailLive.Edit, :edit
      live "/emails/:id/:language/code", App.EmailLive.Edit, :code
      live "/emails/:id/:language/styles", App.EmailLive.Edit, :styles

      # Reports
      live "/reports", App.ReportLive.Index, :index

      # Embed & API
      live "/embed/secrets", App.EmbedLive.Index, :secrets
      live "/embed/api-usage", App.EmbedLive.Index, :api_usage
      live "/embed/login-page", App.EmbedLive.Index, :login_page
      live "/embed/auth-guard", App.EmbedLive.Index, :auth_guard

      # Team
      live "/team", App.TeamLive.Index, :index
      live "/team/invite", App.TeamLive.Index, :invite
      live "/team/:id/edit", App.TeamLive.Index, :edit
      live "/team/:id/delete", App.TeamLive.Index, :delete

      # App
      live "/app", App.AppLive.Index, :index
      live "/app/new", App.AppLive.Index, :new
      live "/app/delete", App.AppLive.Index, :delete

      # Domain
      live "/domain", App.DomainLive.Index, :index
      live "/domain/dns", App.DomainLive.Index, :dns
      live "/domain/change", App.DomainLive.Index, :change

      # Billing
      live "/billing", App.BillingLive.Index, :index
      live "/subscribe/success", App.BillingLive.SubscribeSuccessLive, :index
      live "/subscribe", App.BillingLive.SubscribeLive, :index

      # Profile
      live "/profile", User.ProfileLive

      # User
      live "/edit-email", User.ProfileLive, :change_email
      live "/password", User.PasswordLive, :index
      live "/password/change", User.PasswordLive, :change
      live "/invitations", User.InvitationsLive
      live "/security", User.SecurityLive

      # Org
      live "/organization", Org.EditLive, :index
      live "/organization/new", Org.EditLive, :new

      # Apps
      live "/apps", App.AppLive.Index, :index
      live "/apps/new", App.AppLive.Index, :new

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
