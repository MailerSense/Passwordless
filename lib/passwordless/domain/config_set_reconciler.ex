defmodule Passwordless.Domain.ConfigSetReconciler do
  @moduledoc """
  Reconciles the state of local settings with SES configsets
  """
  use Oban.Pro.Worker, queue: :domain, max_attempts: 1, tags: ["config_set", "reconciler"]

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
      %Domain{app: %App{settings: %AppSettings{}} = app} = domain ->
        client = Session.get_client!()

        with :ok <- update_tracking_options(client, app),
             :ok <- update_event_destination(client, app.settings) do
          Logger.info("Successfully updated configset event destination for #{domain.name}")
          :ok
        else
          error ->
            Logger.error("Failed to update configset event destination for #{domain.name}: #{inspect(error)}")
            {:error, error}
        end

      nil ->
        Logger.error("Domain not found for ID: #{domain_id}")
        {:cancel, :domain_not_found}
    end
  end

  defp update_tracking_options(
         %AWS.Client{} = client,
         %App{settings: %AppSettings{email_tracking: email_tracking, email_configuration_set: config_set_name}} = app
       ) do
    tracking_domain =
      case Passwordless.get_fallback_domain(app, :tracking) do
        {:ok, tracking_domain} -> tracking_domain
        _ -> nil
      end

    params =
      case {email_tracking, tracking_domain} do
        {true, %Domain{} = domain} ->
          %{
            "HttpsPolicy" => "REQUIRE",
            "CustomRedirectDomain" => domain.name
          }

        _ ->
          %{}
      end

    with {:ok, _, _} <-
           AWS.SESv2.put_configuration_set_tracking_options(client, config_set_name, params),
         do: :ok
  end

  defp update_event_destination(%AWS.Client{} = client, %AppSettings{
         email_tracking: email_tracking,
         email_configuration_set: config_set_name,
         email_event_destination: destination_name
       }) do
    params = %{
      "EventDestination" => %{
        "MatchingEventTypes" =>
          [
            "SEND",
            "REJECT",
            "BOUNCE",
            "COMPLAINT",
            "DELIVERY",
            "RENDERING_FAILURE",
            "DELIVERY_DELAY",
            "SUBSCRIPTION"
          ]
          |> append_if("OPEN", email_tracking)
          |> append_if("CLICK", email_tracking)
      }
    }

    with {:ok, _, _} <-
           AWS.SESv2.update_configuration_set_event_destination(client, config_set_name, destination_name, params),
         do: :ok
  end

  defp append_if(list, _value, false), do: list
  defp append_if(list, value, true), do: list ++ List.wrap(value)
end
