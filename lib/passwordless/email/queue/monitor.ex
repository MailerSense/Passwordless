defmodule Passwordless.Email.Queue.Monitor do
  @moduledoc """
  Monitors the health of the event sources.
  """

  use GenServer

  alias Passwordless.Email.Queue.Manager
  alias Passwordless.Email.Queue.Source

  require Logger

  @cache_key "event_source_monitor_state"
  @unhealthy_threshold 5

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def record_failure(%Source{} = source) do
    GenServer.cast(__MODULE__, {:record_failure, source})
  end

  # Server

  @impl true
  def init(state) when is_map(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:record_failure, %Source{id: source_id} = source}, state) do
    state =
      state
      |> Map.put_new(source_id, Cache.get(cache_key(source_id)) || 0)
      |> Map.update(source_id, 0, fn
        i when is_integer(i) -> i + 1
        o -> o
      end)
      |> case do
        %{^source_id => :unhealthy} ->
          Logger.warning("Source #{source_id} is already unhealthy")
          state

        %{^source_id => count} when count >= @unhealthy_threshold ->
          with :ok <- Manager.terminate_pipeline(source) do
            Logger.warning("Source #{source_id} marked as unhealthy, pipeline stopped")
          end

          Map.put(state, source_id, :unhealthy)

        state ->
          state
      end
      |> store_state(source_id)

    {:noreply, state}
  end

  # Private

  defp cache_key(source_id) do
    "#{@cache_key}_#{source_id}"
  end

  defp store_state(state, source_id) do
    Cache.put(cache_key(source_id), state[source_id], ttl: :timer.hours(6))
    state
  end
end
