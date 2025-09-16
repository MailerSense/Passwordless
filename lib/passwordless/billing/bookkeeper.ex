defmodule Passwordless.Billing.Bookkeeper do
  @moduledoc """
  Periodically deletes email identities that have not passed AWS SES verification.
  """

  use Oban.Worker, queue: :billing, max_attempts: 1, tags: ["billing", "bookkeeper"]

  require Logger

  @task_opts [
    ordered: false,
    timeout: :timer.minutes(5),
    max_concurrency: 20
  ]

  @impl true
  def process(%Oban.Job{meta: %{"cron" => true}}) do
    :ok
  end
end
