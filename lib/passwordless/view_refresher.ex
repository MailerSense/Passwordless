defmodule Passwordless.ViewRefresher do
  @moduledoc """
  Periodically deletes email identities that have not passed AWS SES verification.
  """

  use Oban.Pro.Worker, queue: :statistics, max_attempts: 1, tags: ["database", "view", "refresher"]

  import SqlFmt.Helpers

  alias Database.Tenant
  alias Passwordless.Repo

  require Logger

  @task_opts [
    ordered: false,
    timeout: :timer.minutes(5),
    max_concurrency: 10
  ]

  @views [
    {:app, :concurrent, "action_template_unique_users"},
    {:app, :concurrent, "action_template_monthly_stats"}
  ]

  @impl true
  def process(%Oban.Job{meta: %{"cron" => true}}) do
    public_queries =
      for {_d, m, v} <- Enum.filter(@views, fn {domain, _, _} -> domain == :public end),
          do:
            (
              case_result =
                case m do
                  :sequential -> ~SQL"REFRESH MATERIALIZED VIEW view_name;"
                  :concurrent -> ~SQL"REFRESH MATERIALIZED VIEW CONCURRENTLY view_name;"
                end

              String.replace(case_result, "view_name", v)
            )

    schema_queries =
      for u <- Tenant.all(),
          {_d, m, v} <- Enum.filter(@views, fn {domain, _, _} -> domain == :app end),
          do:
            (
              case_result =
                case m do
                  :sequential -> ~SQL"REFRESH MATERIALIZED VIEW prefix.view_name;"
                  :concurrent -> ~SQL"REFRESH MATERIALIZED VIEW CONCURRENTLY prefix.view_name;"
                end

              case_result
              |> String.replace("prefix", u)
              |> String.replace("view_name", v)
            )

    (public_queries ++ schema_queries)
    |> Task.async_stream(&Ecto.Adapters.SQL.query(Repo, &1), @task_opts)
    |> Stream.each(fn
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error("Failed to refresh view: #{inspect(error)}")
    end)
    |> Stream.run()

    :ok
  end
end
