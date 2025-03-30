defmodule Passwordless.Email.Queue.Consumer do
  @moduledoc """
  Consumes events from Amazon SQS/SNS and converts them to email logs.
  """

  alias Passwordless.Email
  alias Passwordless.Email.Queue.Message
  alias Passwordless.Email.Queue.Source

  def start_link(%Message{data: data, source: %Source{} = source} = message) do
    Task.start_link(fn ->
      Email.create_message_from_event(data)
      Message.ack(message)
    end)
  end
end
