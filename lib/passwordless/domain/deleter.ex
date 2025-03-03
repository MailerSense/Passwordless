defmodule Passwordless.Identity.Deleter do
  @moduledoc """
  Periodically deletes email identities that have not passed AWS SES verification.
  """

  use Oban.Pro.Worker, queue: :identity_ops, max_attempts: 5, tags: ["email", "identities", "deleter"]

  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.Repo

  require Logger

  @impl true
  def process(%Oban.Job{meta: %{"cron" => true}}) do
    Domain
    |> Domain.get_by_state(:aws_failed)
    |> Repo.all()
    |> Repo.preload(:app)
    |> Enum.filter(fn
      %Domain{state: :aws_failed, updated_at: %DateTime{} = updated_at} ->
        Timex.diff(DateTime.utc_now(), updated_at, :hours) > 6

      %Domain{} ->
        false
    end)
    |> Enum.each(fn
      %Domain{app: %App{} = app} = domain ->
        Logger.warning("Soft deleting domain #{domain.name}")
        Repo.soft_delete(domain, prefix: Database.Tenant.to_prefix(app))

        with %AWS.Client{} = client <- Cloud.get_client(),
             {:ok, %{}, _} <- AWS.SESv2.delete_email_identity(client, domain.name, %{}) do
          Logger.info("Deleted domain #{domain.name} from SES")
        else
          {:error, error} ->
            Logger.error("Failed to delete domain #{domain.name} from SES: #{inspect(error)}")
        end

        :ok

      _ ->
        :ok
    end)
  end
end
