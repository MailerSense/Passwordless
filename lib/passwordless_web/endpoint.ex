defmodule PasswordlessWeb.Endpoint do
  @moduledoc """
  The endpoint for the Passwordless application
  """
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :passwordless

  alias PasswordlessWeb.Plugs.HealthCheck

  if sandbox = Application.compile_env(:passwordless, :sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox, sandbox: sandbox
  end

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [
      compress: Mix.env() == :prod,
      connect_info: [
        :peer_data,
        :uri,
        :user_agent,
        :x_headers,
        session: Application.compile_env!(:passwordless, :session)
      ]
    ]

  plug HealthCheck

  plug Plug.Static,
    at: "/",
    from: :passwordless,
    gzip: Mix.env() == :prod,
    only: PasswordlessWeb.static_paths(),
    cache_control_for_etags: "public, max-age=31536000"

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :passwordless
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Stripe.WebhookPlug,
    at: "/webhooks/stripe",
    handler: Passwordless.Billing.Providers.Stripe.WebhookHandler,
    secret: {Application, :get_env, [:stripity_stripe, :signing_secret]}

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Sentry.PlugContext

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, Application.compile_env!(:passwordless, :session)
  plug Corsica, Application.compile_env!(:passwordless, :cors)

  plug PasswordlessWeb.Router
end
