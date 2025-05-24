defmodule PasswordlessWeb.Router do
  use PasswordlessWeb, :router

  import PasswordlessWeb.Plugs.App
  import PasswordlessWeb.Plugs.Org
  import PasswordlessWeb.Plugs.ParseIP
  import PasswordlessWeb.UserAuth

  alias Passwordless.Organizations.Org, as: AccountOrg
  alias PasswordlessWeb.FallbackController

  pipeline :browser do
    plug :parse_ip
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PasswordlessWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_content_security_policy, {:config, :content_security_policy}
    plug :fetch_current_user
    plug :fetch_active_user
    plug :fetch_impersonator_user
    plug PasswordlessWeb.Plugs.SetLocale, gettext: PasswordlessWeb.Gettext
  end

  pipeline :public_browser do
    plug :parse_ip
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PasswordlessWeb.Layouts, :root}
    plug :put_layout, false
    plug :protect_from_forgery
    plug :put_content_security_policy, {:config, :content_security_policy}
    plug :rate_limit_public, name: "app_public_browser", limit: 60
  end

  pipeline :public_api do
    plug :accepts, ["json"]
    plug :rate_limit_public, name: "app_public_api", limit: 60
  end

  pipeline :public_layout do
    plug :put_layout, html: {PasswordlessWeb.Layouts, :public}
  end

  pipeline :authenticated do
    plug :require_authenticated_user
    plug :require_onboarded_user
    plug :fetch_current_org
    plug :fetch_current_app
    plug :rate_limit_authenticated, name: "app_authenticated", limit: 120
  end

  pipeline :authenticated_only do
    plug :require_authenticated_user
    plug :fetch_current_org
    plug :fetch_current_app
    plug :rate_limit_authenticated, name: "app_authenticated_only", limit: 120
  end

  scope "/", PasswordlessWeb do
    pipe_through [:browser, :authenticated_only]

    # Accept invitation to the organization
    post "/invitation/accept", OrgController, :accept_invitation
  end

  scope "/unsubscribe", PasswordlessWeb do
    pipe_through :public_api

    post "/email/:token", EmailSubscriptionController, :unsubscribe_email
  end

  scope "/unsubscribe/ui", PasswordlessWeb do
    pipe_through :public_browser

    get "/email/:token/confirm", EmailSubscriptionPageController, :show
    post "/email/:token/confirm", EmailSubscriptionPageController, :show

    post "/email/finalize", EmailSubscriptionPageController, :finalize
  end

  # App routes - for signed in and confirmed users only
  scope "/", PasswordlessWeb do
    pipe_through [:browser, :authenticated]

    # Home
    get "/", HomeController, :index

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
    get "/domain/:id/dns/download", DNSController, :download

    # Import
    get "/actor-import/csv/download", UserImportController, :download_csv
    get "/actor-import/excel/download", UserImportController, :download_excel

    # Recovery codes
    get "/recovery-codes/download/:user_id", RecoveryCodeController, :download

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
      live "/users", App.UserLive.Index, :index
      live "/users/new", App.UserLive.Index, :new
      live "/users/import", App.UserLive.Index, :import
      live "/users/:id/edit", App.UserLive.Index, :edit
      live "/users/:id/delete", App.UserLive.Index, :delete

      # User Pools
      live "/user-pools", App.UserPoolLive.Index, :index
      live "/user-pools/new", App.UserPoolLive.Index, :new
      live "/user-pools/:id/edit", App.UserPoolLive.Index, :edit
      live "/user-pools/:id/delete", App.UserPoolLive.Index, :delete

      # Actions
      live "/actions", App.ActionLive.Index, :index
      live "/actions/new", App.ActionLive.Index, :new
      live "/actions/run-test", App.ActionLive.Index, :run_test
      live "/actions/:id/delete", App.ActionLive.Index, :delete
      live "/actions/:id/edit", App.ActionLive.Edit, :edit
      live "/actions/:id/edit/delete", App.ActionLive.Edit, :delete
      live "/actions/:id/embed", App.ActionLive.Embed, :embed
      live "/actions/:id/embed/delete", App.ActionLive.Embed, :delete
      live "/actions/:id/activity", App.ActionLive.Activity, :activity
      live "/actions/:id/activity/delete", App.ActionLive.Activity, :delete

      # Authenticators
      live "/authenticators/email-otp", App.AuthenticatorLive.Index, :email_otp
      live "/authenticators/magic-link", App.AuthenticatorLive.Index, :magic_link
      live "/authenticators/passkey", App.AuthenticatorLive.Index, :passkey
      live "/authenticators/security-key", App.AuthenticatorLive.Index, :security_key
      live "/authenticators/totp", App.AuthenticatorLive.Index, :totp
      live "/authenticators/recovery-codes", App.AuthenticatorLive.Index, :recovery_codes

      # Email
      live "/emails/:id/:language/edit", App.EmailLive.Edit, :edit
      live "/emails/:id/:language/code", App.EmailLive.Edit, :code
      live "/emails/:id/:language/files", App.EmailLive.Edit, :files

      # Reports
      live "/reports", App.ReportLive.Index, :index

      # Embed & API
      live "/embed/install", App.EmbedLive.Index, :install
      live "/embed/api", App.EmbedLive.Index, :api
      live "/embed/ui", App.EmbedLive.Index, :ui
      live "/embed/rules-engine", App.EmbedLive.Index, :rules_engine

      # Team
      live "/team", App.TeamLive.Index, :index
      live "/team/invite", App.TeamLive.Index, :invite
      live "/team/:id/edit", App.TeamLive.Index, :edit
      live "/team/:id/delete", App.TeamLive.Index, :delete
      live "/team/invitation/:invitation_id/resend", App.TeamLive.Index, :resend_invitation
      live "/team/invitation/:invitation_id/delete", App.TeamLive.Index, :delete_invitation

      # App
      live "/apps", App.AppLive.Index, :index
      live "/apps/new", App.AppLive.Index, :new
      live "/apps/:id/edit", App.AppLive.Index, :edit
      live "/apps/:id/delete", App.AppLive.Index, :delete

      # Domain
      live "/domain", App.DomainLive.Index, :index
      live "/domain/:kind/dns", App.DomainLive.Index, :dns
      live "/domain/:kind/new", App.DomainLive.Index, :new
      live "/domain/:kind/change", App.DomainLive.Index, :change
      live "/domain/delete", App.DomainLive.Index, :delete

      # Billing
      live "/billing", App.BillingLive.Index, :index
      live "/billing/item/:id/edit", App.BillingLive.Index, :edit_billing_item
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

      # Knowledge
      live "/support", Knowledge.SupportLive, :index
      live "/use-cases", Knowledge.UseCaseLive, :index
    end
  end

  scope "/" do
    use PasswordlessApi.Routes
    use PasswordlessWeb.AuthRoutes
    use PasswordlessWeb.AdminRoutes
    use PasswordlessWeb.DevRoutes
  end

  @doc """
  Rate limits the API requests.
  """
  def rate_limit_authenticated(conn, opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    key = "#{name}_#{get_current_org_id(conn)}"
    scale = Keyword.get(opts, :scale, :timer.minutes(1))
    limit = Keyword.get(opts, :limit, 200)

    case Passwordless.RateLimit.hit(key, scale, limit) do
      {:allow, _count} ->
        conn

      {:deny, _retry_after} ->
        conn
        |> FallbackController.call({:error, :too_many_requests})
        |> halt()
    end
  end

  @doc """
  Rate limits the API requests.
  """
  def rate_limit_public(conn, opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    key = "#{name}_#{get_current_user_ip(conn)}"
    scale = Keyword.get(opts, :scale, :timer.minutes(1))
    limit = Keyword.get(opts, :limit, 200)

    case Passwordless.RateLimit.hit(key, scale, limit) do
      {:allow, _count} ->
        conn

      {:deny, _retry_after} ->
        conn
        |> FallbackController.call({:error, :too_many_requests})
        |> halt()
    end
  end

  @doc """
  Fetches the current org id from the connection.
  """
  def get_current_org_id(%Plug.Conn{assigns: %{current_org: %AccountOrg{id: org_id}}}) when is_binary(org_id), do: org_id
  def get_current_org_id(%Plug.Conn{}), do: nil

  @doc """
  Fetches the current org id from the connection.
  """
  def get_current_user_ip(%Plug.Conn{assigns: %{current_user_ip: ip}}) when is_binary(ip), do: ip
  def get_current_user_ip(%Plug.Conn{}), do: nil
end
