defmodule Passwordless.Domain.Creator do
  @moduledoc """
  Creates SES domain identities with EasyDKIM verification and configures SES ConfigurationSets.
  """
  use Oban.Pro.Worker, queue: :domain, tags: ["domain", "creator"]

  alias Passwordless.App
  alias Passwordless.AppSettings
  alias Passwordless.AWS.Session
  alias Passwordless.Domain
  alias Passwordless.Repo

  require Logger

  @impl true
  def process(%Oban.Job{args: %{"domain_id" => domain_id}}) when is_binary(domain_id) do
    case domain_id |> Passwordless.get_domain() |> Repo.preload([{:app, [:settings]}]) do
      %Domain{app: %App{settings: %AppSettings{} = settings} = app} = domain ->
        config_set_name = Domain.config_set_name(domain)

        tracking_domain =
          case Passwordless.get_fallback_domain(app, :tracking) do
            {:ok, tracking_domain} -> tracking_domain
            _ -> nil
          end

        client = Session.get_client!()

        with {:ok, settings} <- Passwordless.update_app_settings(settings, %{email_tracking: true}),
             {:ok, config_set} <- create_configuration_set(client, config_set_name, tracking_domain),
             {:ok, settings} <- Passwordless.update_app_settings(settings, %{email_configuration_set: config_set}),
             {:ok, topic_arn} <- create_topic(client, config_set),
             {:ok, settings} <- Passwordless.update_app_settings(settings, %{email_event_topic_arn: topic_arn}),
             {:ok, subscription_arn} <-
               subscribe_topic_to_queue(client, topic_arn, Passwordless.config([:aws_current, :ses_queue_arn])),
             {:ok, settings} <-
               Passwordless.update_app_settings(settings, %{email_event_topic_subscription_arn: subscription_arn}),
             {:ok, destination} <- create_event_destination(client, config_set, topic_arn),
             {:ok, _settings} <- Passwordless.update_app_settings(settings, %{email_event_destination: destination}),
             {:ok, domain} <- create_email_identity(client, domain, app, config_set) do
          Logger.info("Successfully created domain identity and configuration set for #{domain.name}")
          {:ok, domain.name}
        else
          error ->
            Logger.error("Failed to create domain identity for #{domain.name}: #{inspect(error)}")
            {:error, error}
        end

      other ->
        Logger.error("Domain not found for ID #{domain_id}: #{inspect(other)}")
        {:cancel, :domain_not_found}
    end
  end

  # Private

  defp create_configuration_set(%AWS.Client{} = client, config_set_name, tracking_domain) do
    params = %{
      "ConfigurationSetName" => config_set_name,
      "SendingEnabled" => %{
        "Enabled" => true
      },
      "SuppressionOptions" => %{
        "SuppressedReasons" => ["BOUNCE", "COMPLAINT"]
      }
    }

    delivery_params = %{
      "TlsPolicy" => "Require"
    }

    with {:ok, _, _} <- AWS.SESv2.create_configuration_set(client, params),
         {:ok, _, _} <- AWS.SESv2.put_configuration_set_delivery_options(client, config_set_name, delivery_params) do
      case tracking_domain do
        %Domain{name: name, purpose: :tracking} ->
          tracking_params = %{
            "HttpsPolicy" => "Require",
            "CustomRedirectDomain" => name
          }

          with {:ok, _, _} <- AWS.SESv2.put_configuration_set_tracking_options(client, config_set_name, tracking_params),
               do: {:ok, config_set_name}

        _ ->
          {:ok, config_set_name}
      end
    end
  end

  defp create_topic(%AWS.Client{} = client, config_set_name) do
    with {:ok, %{"TopicArn" => topic_arn}, _} <-
           AWS.SNS.create_topic(client, %{
             "Name" => "#{config_set_name}-topic"
           }),
         do: {:ok, topic_arn}
  end

  defp subscribe_topic_to_queue(%AWS.Client{} = client, topic_arn, queue_arn) do
    with {:ok, %{"SubscriptionArn" => subscription_arn}, _} <-
           AWS.SNS.subscribe(client, %{
             "TopicArn" => topic_arn,
             "Protocol" => "sqs",
             "Endpoint" => queue_arn,
             "ReturnSubscriptionArn" => true
           }),
         do: {:ok, subscription_arn}
  end

  defp create_event_destination(%AWS.Client{} = client, config_set_name, topic_arn) do
    destination_name = "#{config_set_name}-track"

    params = %{
      "EventDestination" => %{
        "Enabled" => true,
        "SnsDestination" => %{
          "TopicArn" => topic_arn
        },
        "MatchingEventTypes" => [
          "SEND",
          "REJECT",
          "BOUNCE",
          "COMPLAINT",
          "DELIVERY",
          "RENDERING_FAILURE",
          "DELIVERY_DELAY",
          "SUBSCRIPTION",
          "OPEN",
          "CLICK"
        ]
      },
      "EventDestinationName" => destination_name
    }

    with {:ok, _, _} <- AWS.SESv2.create_configuration_set_event_destination(client, config_set_name, params),
         do: {:ok, destination_name}
  end

  defp create_email_identity(%AWS.Client{} = client, %Domain{purpose: :email} = domain, %App{} = app, config_set_name) do
    params = %{
      "EmailIdentity" => domain.name,
      "ConfigurationSetName" => config_set_name,
      "Tags" => [
        %{
          "Key" => "app_id",
          "Value" => app.id
        },
        %{
          "Key" => "org_id",
          "Value" => app.org_id
        },
        %{
          "Key" => "purpose",
          "Value" => "email"
        }
      ]
    }

    mail_from_params = %{
      "MailFromDomain" => Domain.envelope(domain),
      "BehaviorOnMxFailure" => "REJECT_MESSAGE"
    }

    with {:ok,
          %{
            "IdentityType" => "DOMAIN",
            "DkimAttributes" => [_ | _] = dkim_attributes,
            "VerifiedForSendingStatus" => verified_status
          }, _} <- AWS.SESv2.create_email_identity(client, params),
         {:ok, _, _} <- AWS.SESv2.put_email_identity_mail_from_attributes(client, domain.name, mail_from_params),
         {:ok, domain} <- create_dns_records(domain, dkim_attributes, verified_status),
         do: update_domain_state(domain, verified_status)
  end

  defp update_domain_state(%Domain{} = domain, true = _verified_status) do
    Passwordless.update_domain(domain, %{state: :aws_verified})
  end

  defp update_domain_state(%Domain{} = domain, false = _verified_status) do
    {:ok, domain}
  end

  defp create_dns_records(%Domain{} = domain, dkim_attributes, verified_status) do
    results =
      [
        create_dkim_records(domain, dkim_attributes, verified_status),
        create_mail_from_records(domain),
        create_dmarc_record(domain)
      ]
      |> Enum.flat_map(&Function.identity/1)
      |> Enum.map(&Passwordless.create_domain_record(domain, &1))

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:ok, Repo.preload(domain, :records, force: true)}
    else
      {:error, :failed_to_create_domain_records}
    end
  end

  defp create_dkim_records(%Domain{} = domain, dkim_tokens, verified_status) do
    subdomain = Domain.subdomain(domain)

    Enum.map(dkim_tokens, fn token ->
      name = "#{token}._domainkey.#{subdomain}"
      value = "#{token}.dkim.amazonses.com"
      %{kind: :cname, name: name, value: value, verified: verified_status}
    end)
  end

  defp create_mail_from_records(%Domain{} = domain) do
    name = Domain.envelope_subdomain(domain)
    region = Passwordless.config([:aws_current, :region])

    [
      %{kind: :mx, name: name, value: "feedback-smtp.#{region}.amazonses.com", priority: 10},
      %{kind: :txt, name: name, value: "v=spf1 include:amazonses.com ~all"}
    ]
  end

  defp create_dmarc_record(%Domain{} = domain) do
    [
      %{
        kind: :txt,
        name: "_dmarc.#{Domain.subdomain(domain)}",
        value: "v=DMARC1; p=none; rua=mailto:dmarc@#{domain.name};"
      }
    ]
  end
end
