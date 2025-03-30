defmodule Passwordless.EventQueue.Deduplicator do
  @moduledoc """
  Deduplicates SQS messages based on their IDs.
  """

  use GenStage

  alias Passwordless.EventQueue.Message
  alias Passwordless.EventQueue.Producer
  alias Passwordless.EventQueue.Source

  @registry Passwordless.EventQueue.Registry

  def start_link(%Source{} = source) do
    GenStage.start_link(__MODULE__, source, name: via(source.id))
  end

  @impl true
  def init(%Source{} = source) do
    producers =
      for index <- 1..10,
          do: {Producer.via(source.id, index), []}

    {:producer_consumer, source, subscribe_to: producers}
  end

  @impl true
  def handle_events(events, _from, %Source{} = source) do
    {:noreply, filter_duplicates(events), source}
  end

  def via(source_id) when is_binary(source_id) do
    {:via, Registry, {@registry, {__MODULE__, source_id}}}
  end

  # Private

  defp filter_duplicates(messages) when is_list(messages) do
    Enum.filter(messages, fn
      %Message{data: nil} = message ->
        Message.ack(message)
        false

      %Message{} = message ->
        key = duplicate_key(message)

        if Cache.exists?(key) do
          Message.ack(message)
          false
        else
          Cache.put(key, true, ttl: :timer.minutes(5))
          true
        end
    end)
  end

  defp duplicate_key(%Message{id: id}) when is_binary(id), do: "sqs-msg-" <> id
end
