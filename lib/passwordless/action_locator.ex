defmodule Passwordless.ActionLocator do
  @moduledoc """
  This module is responsible for locating actions.
  """

  use Oban.Pro.Worker, queue: :mailer, max_attempts: 5, tags: ["mailer", "executor"]

  alias Passwordless.Mailer

  @impl true
  def process(%Oban.Job{args: %{"email" => email_args}}) do
    with {:ok, _metadata} <- Mailer.deliver(Mailer.from_map(email_args)) do
      :ok
    end
  end
end
