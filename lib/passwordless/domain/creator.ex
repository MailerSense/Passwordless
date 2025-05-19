defmodule Passwordless.Domain.Creator do
  @moduledoc """
  Reconciles the state of local settings with SES configsets
  """
  use Oban.Pro.Worker, queue: :domain, max_attempts: 5, tags: ["domain", "creator"]

  alias Passwordless.App
  alias Passwordless.AppSettings
  alias Passwordless.AWS.Session
  alias Passwordless.Domain
  alias Passwordless.Repo

  require Logger

  @impl true
  def process(%Oban.Job{args: %{"domain_id" => domain_id}}) when is_binary(domain_id) do
    case domain_id |> Passwordless.get_domain() |> Repo.preload([{:app, [:settings]}]) do
      %Domain{
        app:
          %App{
            settings: %AppSettings{
              email_tracking: email_tracking,
              email_configuration_set: config_set
            }
          } = app
      } = domain ->
        client = Session.get_client!()

        params = %{
          "ConfigurationSetName" => "test",
          "DkimSigningAttributes" => %{},
          "Tags" => [
            %{
              "Key" => "app_id",
              "Value" => app.id
            }
          ],
          "EmailIdentity" => domain.name
        }

        case AWS.SESv2.create_email_identity(client, params) do
          {:ok,
           %{
             "DkimAttributes" => %{
               "CurrentSigningKeyLength" => list(any()),
               "LastKeyGenerationTimestamp" => non_neg_integer(),
               "NextSigningKeyLength" => list(any()),
               "SigningAttributesOrigin" => list(any()),
               "SigningEnabled" => boolean(),
               "Status" => list(any()),
               "Tokens" => list(String.t()())
             },
             "IdentityType" => "DOMAIN",
             "VerifiedForSendingStatus" => verified_for_sending_status
           }, _} ->
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
