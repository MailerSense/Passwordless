defmodule Passwordless.Domain.ConfigSetReconciler do
  @moduledoc """
  Reconciles the state of local settings with SES configsets
  """
  use Oban.Pro.Worker, queue: :domain, max_attempts: 5, tags: ["config_set", "reconciler"]

  alias Passwordless.App
  alias Passwordless.AppSettings
  alias Passwordless.AWS.Session
  alias Passwordless.Domain
  alias Passwordless.Repo

  require Logger

  @impl true
  def process(%Oban.Job{
        args: %{"change" => "toggle_tracking", "domain_id" => domain_id, "tracking_domain" => tracking_domain}
      })
      when is_binary(domain_id) do
    case domain_id |> Passwordless.get_domain() |> Repo.preload([{:app, [:settings]}]) do
      %Domain{
        app: %App{
          settings: %AppSettings{
            email_tracking: email_tracking,
            email_configuration_set: config_set
          }
        }
      } = domain ->
        client = Session.get_client!()

        params =
          if email_tracking do
            %{
              "CustomRedirectDomain" => tracking_domain,
              "HttpsPolicy" => "REQUIRE"
            }
          else
            %{}
          end

        case AWS.SESv2.put_configuration_set_tracking_options(client, config_set, params) do
          {:ok, _, _} ->
            Logger.info("Successfully update configset tracking options for #{domain.name}")
            :ok

          error ->
            Logger.error("Failed to update configset tracking options for #{domain.name}: #{inspect(error)}")
            {:error, error}
        end

      nil ->
        Logger.error("Domain not found for ID: #{domain_id}")
        {:cancel, :domain_not_found}
    end
  end
end
