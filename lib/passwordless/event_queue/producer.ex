defmodule Passwordless.EventQueue.Producer do
  @moduledoc """
  Producer for Amazon SQS/SNS events
  """

  use GenStage

  alias Passwordless.AWS.Session
  alias Passwordless.EventQueue.Message
  alias Passwordless.EventQueue.Source

  require Logger

  @registry Passwordless.EventQueue.Registry
  @max_messages 10
  @receive_interval :timer.seconds(5)
  @default_receive_opts %{"WaitTimeSeconds" => 10, "VisibilityTimeout" => 30}

  defmodule State do
    @moduledoc false
    use TypedStruct

    alias Passwordless.EventQueue.Source

    typedstruct do
      field :source, Source.t(), enforce: true
      field :demand, non_neg_integer(), enforce: true
      field :attempt, non_neg_integer(), enforce: true
      field :receive_timer, pid() | nil, enforce: true
    end
  end

  def start_link([%Source{} = source, index]) do
    GenStage.start_link(__MODULE__, source, name: via(source.id, index))
  end

  @impl true
  def init(%Source{} = source) do
    {:producer,
     %State{
       source: source,
       demand: 0,
       attempt: 0,
       receive_timer: nil
     }}
  end

  @impl true
  def handle_demand(incoming_demand, %State{demand: demand} = state) do
    handle_receive_messages(%State{state | demand: demand + incoming_demand})
  end

  @impl true
  def handle_info(:receive_messages, %State{receive_timer: nil} = state) do
    {:noreply, [], state}
  end

  @impl true
  def handle_info(:receive_messages, %State{} = state) do
    handle_receive_messages(%{state | receive_timer: nil})
  end

  @impl true
  def handle_info(_, %State{} = state) do
    {:noreply, [], state}
  end

  def via(source_id, index) when is_integer(index) do
    {:via, Registry, {@registry, {__MODULE__, source_id, index}}}
  end

  # Private

  defp handle_receive_messages(%State{receive_timer: nil, demand: demand} = state) when demand > 0 do
    case receive_messages(state, demand) do
      {:ok, messages} ->
        new_demand = demand - length(messages)

        receive_timer =
          case {messages, new_demand} do
            {[], _} -> schedule_receive_messages(@receive_interval)
            {_, 0} -> nil
            _ -> schedule_receive_messages(0)
          end

        {:noreply, messages, %State{state | demand: new_demand, receive_timer: receive_timer}}

      {:error, error} ->
        Logger.error("Failed to receive messages: #{inspect(error)}")
        receive_timer = schedule_receive_messages(backoff(state.attempt))
        {:noreply, [], %State{state | receive_timer: receive_timer, attempt: state.attempt + 1}}
    end
  end

  defp handle_receive_messages(%State{} = state) do
    {:noreply, [], state}
  end

  defp receive_messages(%State{source: %Source{sqs_queue_url: queue_url} = source}, demand)
       when is_binary(queue_url) and is_integer(demand) do
    client = Session.get_client!()
    receive_request = demand |> receive_message_opts() |> Map.put("QueueUrl", queue_url)

    case AWS.SQS.receive_message(client, receive_request) do
      {:ok, %{"Messages" => messages}, _} when is_list(messages) ->
        {:ok, wrap_messages(messages, queue_url, source)}

      value ->
        Logger.error("Failed to receive messages: #{inspect(value)}")
        {:error, value}
    end
  end

  defp receive_messages(%State{} = _state, _demand), do: {:ok, []}

  defp wrap_messages(messages, queue_url, %Source{} = source) when is_list(messages) and is_binary(queue_url) do
    Enum.map(messages, fn %{"MessageId" => message_id} = message ->
      data =
        with %{"Body" => body} when is_binary(body) <- message,
             {:ok, decoded} <- Jason.decode(body) do
          decoded
        else
          _ -> nil
        end

      acknowledger =
        case message do
          %{"ReceiptHandle" => receipt_handle} when is_binary(receipt_handle) ->
            fn ->
              client = Session.get_client!()
              delete_request = %{"QueueUrl" => queue_url, "ReceiptHandle" => receipt_handle}
              with {:ok, _, _} <- AWS.SQS.delete_message(client, delete_request), do: :ok
            end

          _ ->
            nil
        end

      %Message{
        id: message_id,
        data: data,
        source: source,
        acknowledger: acknowledger
      }
    end)
  end

  defp receive_message_opts(demand) when is_integer(demand),
    do: Map.put(@default_receive_opts, "MaxNumberOfMessages", min(@max_messages, demand))

  defp schedule_receive_messages(interval) do
    Process.send_after(self(), :receive_messages, interval)
  end

  defp backoff(attempt) when attempt >= 0 do
    trunc(:math.pow(attempt, 2) + 5 + :rand.uniform(5) * attempt)
  end
end
