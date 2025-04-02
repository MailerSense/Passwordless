defmodule Passwordless.MailerExecutor do
  @moduledoc """
  This module is responsible for delivering emails using the Mailer module.
  """

  use Oban.Pro.Worker, queue: :mailer, max_attempts: 5, tags: ["mailer", "executor"]

  alias Passwordless.Mailer

  @impl true
  def process(%Oban.Job{args: %{"email" => email_args, "domain_id" => domain_id}}) do
    with {:ok, domain} <- Passwordless.get_domain(domain_id),
         {:ok, _metadata} <- Mailer.deliver_via_domain(Mailer.from_map(email_args), domain) do
      :ok
    end
  end

  @impl true
  def process(%Oban.Job{args: %{"email" => email_args}}) do
    with {:ok, _metadata} <- Mailer.deliver(Mailer.from_map(email_args)) do
      :ok
    end
  end
end
