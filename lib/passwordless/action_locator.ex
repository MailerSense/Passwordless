defmodule Passwordless.ActionLocator do
  @moduledoc """
  This module is responsible for locating actions.
  """

  use Oban.Pro.Worker, queue: :locator, max_attempts: 5, tags: ["action", "locator"]

  alias Passwordless.App
  alias Passwordless.Cache
  alias Passwordless.Event

  @impl true
  def process(%Oban.Job{args: %{"app_id" => app_id, "event_id" => event_id}}) do
    with %App{state: :active} = app <- Passwordless.get_app(app_id),
         %Event{ip_address: ip_address} = event <- Passwordless.get_event(app, event_id),
         {:ok, %{"city" => city, "country_code" => country_code}} <- IPStack.locate(ip_address),
         :ok <- update_cache(ip_address, city, country_code),
         do:
           Passwordless.update_event(app, event, %{
             city: city,
             country: country_code
           })
  end

  # Private

  defp update_cache(ip_address, city, country) do
    Cache.put(
      "ip_loc_" <> ip_address,
      %{"city" => city, "country" => country},
      ttl: :timer.hours(24)
    )

    :ok
  end
end
