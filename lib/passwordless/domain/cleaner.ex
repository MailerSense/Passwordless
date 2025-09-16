defmodule Passwordless.Domain.Cleaner do
  @moduledoc """
  Periodically deletes email identities that have not passed AWS SES verification.
  """

  use Oban.Worker, queue: :domain, max_attempts: 1, tags: ["email", "domains", "deleter"]

  alias Passwordless.Domain
  alias Passwordless.Domain.Deleter
  alias Passwordless.Repo

  require Logger

  @impl true
  def process(%Oban.Job{meta: %{"cron" => true}}) do
    Domain
    |> Domain.get_by_state(:aws_failed)
    |> Domain.get_by_purpose(:email)
    |> Repo.all()
    |> Enum.filter(fn
      %Domain{state: :aws_failed, updated_at: %DateTime{} = updated_at} ->
        Timex.diff(DateTime.utc_now(), updated_at, :hours) > 1

      %Domain{} ->
        false
    end)
    |> Enum.each(fn
      %Domain{purpose: :email} = domain ->
        %{domain_id: domain.id}
        |> Deleter.new()
        |> Oban.insert()

      _ ->
        :ok
    end)

    :ok
  end
end
