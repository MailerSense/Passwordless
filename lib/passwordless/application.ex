defmodule Passwordless.Application do
  @moduledoc false

  use Application

  @secret Application.compile_env!(:passwordless, :secret_manager)
  @secret_name Keyword.fetch!(@secret, :secret_name)

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{
      config: %{metadata: [:file, :line]}
    })

    children =
      if System.get_env("DATABASE_MIGRATION") do
        [
          Passwordless.Vault,
          Passwordless.Repo,
          {Finch, name: Passwordless.Finch},
          {Finch, name: Passwordless.Finch.AWS},
          PasswordlessWeb.Endpoint,
          AWS.Lambda.Monitor.Server,
          AWS.Lambda.Loop
        ]
      else
        [
          Passwordless.Vault,
          Passwordless.Repo,
          PasswordlessWeb.Telemetry,
          {Finch, name: Passwordless.Finch},
          {Finch, name: Passwordless.Finch.Swoosh},
          {Finch, name: Passwordless.Finch.AWS}
        ]
        |> append_if(
          {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies)]},
          Passwordless.config(:env) in [:dev, :prod]
        )
        |> Kernel.++([
          {Phoenix.PubSub, name: Passwordless.PubSub},
          {Task.Supervisor, name: Passwordless.BackgroundTask},
          {Passwordless.SecretVault, @secret_name},
          Cache,
          Passwordless.Email.Queue.Manager,
          {Oban, Application.fetch_env!(:passwordless, Oban)},
          {Passwordless.HealthCheck, health_checks()},
          PasswordlessWeb.Endpoint
        ])
      end

    opts = [strategy: :one_for_one, name: Passwordless.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PasswordlessWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Private

  defp health_checks do
    readiness = [Passwordless.HealthCheck.repo?(Passwordless.Repo)]
    liveness = [Passwordless.HealthCheck.repo?(Passwordless.Repo)]
    {readiness, liveness}
  end

  defp append_if(list, _value, false), do: list
  defp append_if(list, value, true), do: list ++ List.wrap(value)
end
