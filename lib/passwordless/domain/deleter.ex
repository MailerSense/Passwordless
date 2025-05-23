defmodule Passwordless.Domain.Deleter do
  @moduledoc """
  Creates SES domain identities with EasyDKIM verification and configures SES ConfigurationSets.
  """
  use Oban.Pro.Worker, queue: :domain, max_attempts: 1, tags: ["domain", "deleter"]

  alias Database.Tenant
  alias Passwordless.App
  alias Passwordless.AppSettings
  alias Passwordless.AWS.Session
  alias Passwordless.Domain
  alias Passwordless.Repo

  require Logger

  @impl true
  def process(%Oban.Job{args: %{"domain_id" => domain_id}}) when is_binary(domain_id) do
    case domain_id |> Passwordless.get_domain() |> Repo.preload([{:app, [:settings]}]) do
      %Domain{app: %App{settings: %AppSettings{}} = app} = domain ->
        client = Session.get_client!()

        with {:ok, domain} <- delete_email_identity(client, app, domain),
             {:ok, settings} <- delete_event_destination(client, app),
             {:ok, settings} <- delete_topic_subscription(client, %App{app | settings: settings}),
             {:ok, settings} <- delete_topic(client, %App{app | settings: settings}),
             {:ok, settings} <- delete_configuration_set(client, %App{app | settings: settings}),
             {:ok, domain} <- delete_database_domain(app, domain) do
          Logger.info("Successfully deleted domain identity and configuration set for #{domain.name}")
          {:ok, domain.name}
        else
          error ->
            Logger.error("Failed to delete domain identity for #{domain.name}: #{inspect(error)}")
            {:error, error}
        end

      other ->
        Logger.error("Domain not found for ID #{domain_id}: #{inspect(other)}")
        {:cancel, :domain_not_found}
    end
  end

  # Private

  defp delete_email_identity(%AWS.Client{} = client, %App{} = app, %Domain{purpose: :email} = domain) do
    with false <- Domain.system?(domain),
         false <- Domain.verified?(domain) do
      case AWS.SESv2.get_email_identity(client, domain.name) do
        {:ok, _, _} ->
          with {:ok, _, _} <- AWS.SESv2.delete_email_identity(client, domain.name, %{}), do: {:ok, domain}

        _ ->
          {:ok, domain}
      end
    else
      _ -> {:error, :domain_not_allowed_to_delete}
    end
  end

  defp delete_database_domain(%App{} = app, %Domain{purpose: :email} = domain) do
    with false <- Domain.system?(domain),
         false <- Domain.verified?(domain),
         do: Repo.soft_delete(domain, prefix: Tenant.to_prefix(app))
  end

  defp delete_event_destination(%AWS.Client{} = client, %App{
         settings:
           %AppSettings{
             email_configuration_set: email_configuration_set,
             email_event_destination: email_event_destination
           } = settings
       })
       when is_binary(email_configuration_set) and is_binary(email_event_destination) do
    with {:ok, _, _} <-
           AWS.SESv2.delete_configuration_set_event_destination(
             client,
             email_configuration_set,
             email_event_destination,
             %{}
           ),
         do: Passwordless.update_app_settings(settings, %{email_event_destination: nil})
  end

  defp delete_event_destination(%AWS.Client{} = client, %App{settings: %AppSettings{} = settings}), do: {:ok, settings}

  defp delete_topic_subscription(%AWS.Client{} = client, %App{
         settings: %AppSettings{email_event_topic_subscription_arn: email_event_topic_subscription_arn} = settings
       })
       when is_binary(email_event_topic_subscription_arn) do
    with {:ok, _, _} <-
           AWS.SNS.unsubscribe(client, %{
             "SubscriptionArn" => email_event_topic_subscription_arn
           }),
         do: Passwordless.update_app_settings(settings, %{email_event_topic_subscription_arn: nil})
  end

  defp delete_topic_subscription(%AWS.Client{} = client, %App{settings: %AppSettings{} = settings}) do
    {:ok, settings}
  end

  defp delete_topic(%AWS.Client{} = client, %App{
         settings: %AppSettings{email_event_topic_arn: email_event_topic_arn} = settings
       })
       when is_binary(email_event_topic_arn) do
    with {:ok, _, _} <-
           AWS.SNS.delete_topic(client, %{"TopicArn" => email_event_topic_arn}),
         do: Passwordless.update_app_settings(settings, %{email_event_topic_arn: nil})
  end

  defp delete_topic(%AWS.Client{} = _client, %App{settings: %AppSettings{} = settings}) do
    {:ok, settings}
  end

  defp delete_configuration_set(
         %AWS.Client{} = client,
         %App{settings: %AppSettings{email_configuration_set: email_configuration_set} = settings} = app
       )
       when is_binary(email_configuration_set) do
    with {:ok, _, _} <- AWS.SESv2.delete_configuration_set(client, email_configuration_set, %{}),
         do: Passwordless.update_app_settings(settings, %{email_configuration_set: nil})
  end

  defp delete_configuration_set(%AWS.Client{} = _client, %App{settings: %AppSettings{} = settings} = _app),
    do: {:ok, settings}
end
