defmodule Passwordless.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{
      config: %{metadata: [:file, :line]}
    })

    children =
      if System.get_env("DATABASE_MIGRATION") do
        [
          {Finch, name: Passwordless.Finch},
          {Finch, name: Passwordless.Finch.AWS},
          {Passwordless.SecretManager.Vault, app_secret()},
          Passwordless.Vault,
          Passwordless.Repo,
          PasswordlessWeb.Endpoint,
          Passwordless.AWS.Lambda.Monitor.Server,
          Passwordless.AWS.Lambda.Loop
        ]
      else
        [
          {Finch, name: Passwordless.Finch},
          {Finch, name: Passwordless.Finch.Swoosh},
          {Finch, name: Passwordless.Finch.AWS},
          {Passwordless.SecretManager.Vault, app_secret()},
          Passwordless.Vault,
          Passwordless.Repo,
          PasswordlessWeb.Telemetry
        ]
        |> append_if(
          {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies)]},
          Passwordless.config(:env) in [:dev, :prod]
        )
        |> Kernel.++([
          {Phoenix.PubSub, name: Passwordless.PubSub},
          {Task.Supervisor, name: Passwordless.BackgroundTask},
          Passwordless.Cache,
          Passwordless.RateLimit,
          {Oban, Application.fetch_env!(:passwordless, Oban)},
          {Passwordless.EventQueue.Manager, queues()},
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
    key_processes = [
      Passwordless.Repo,
      PasswordlessWeb.Endpoint,
      Passwordless.RateLimit,
      Passwordless.Vault
    ]

    readiness = [Passwordless.HealthCheck.repo?(Passwordless.Repo)]

    liveness =
      Enum.map(key_processes, fn proc ->
        Passwordless.HealthCheck.alive?(fn -> Process.whereis(proc) end)
      end)

    {readiness, liveness}
  end

  defp app_secret do
    Passwordless.config([:secret_manager, :secret_name])
  end

  defp queues do
    append_if(
      [],
      %{id: :sqs_notifications, sqs_queue_url: System.get_env("SES_QUEUE_URL")},
      Util.present?(System.get_env("SES_QUEUE_URL"))
    )
  end

  defp append_if(list, _value, false), do: list
  defp append_if(list, value, true), do: list ++ List.wrap(value)
end
