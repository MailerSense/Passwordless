defmodule Passwordless.ViewRefresher do
  @moduledoc """
  Periodically deletes email identities that have not passed AWS SES verification.
  """

  use Oban.Pro.Worker, queue: :statistics, tags: ["database", "view", "refresher"]

  import SqlFmt.Helpers

  alias Database.Tenant
  alias Passwordless.Repo

  require Logger

  @task_opts [
    ordered: false,
    timeout: :timer.minutes(5)
  ]

  @impl true
  def process(%Oban.Job{meta: %{"cron" => true}}) do
    queries =
      for u <- Tenant.all(),
          {m, v} <- [{:sequential, "user_total"}, {:concurrent, "action_template_unique_users"}],
          do:
            (
              case_result =
                case m do
                  :sequential -> ~SQL"REFRESH MATERIALIZED VIEW prefix.view;"
                  :concurrent -> ~SQL"REFRESH MATERIALIZED VIEW CONCURRENTLY prefix.view;"
                end

              case_result
              |> String.replace("prefix", u)
              |> String.replace("view", v)
            )

    queries
    |> Task.async_stream(&run_query/1, @task_opts)
    |> Stream.run()

    :ok
  end

  defp run_query(query) do
    Ecto.Adapters.SQL.query(Repo, query)
    :ok
  end
end
