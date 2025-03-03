defmodule Passwordless.Identity.Verifier do
  @moduledoc """
  Verifies email identities by checking SES verification status and associated DNS records.
  """

  use Oban.Pro.Worker,
    queue: :identity_ops,
    max_attempts: 5,
    tags: ["email", "identities", "verifier"]

  require Logger

  @impl true
  def process(%Oban.Job{meta: %{"cron" => true}}) do
    :ok
  end

  # Private
end
