defmodule Passwordless.EventQueue.Consumer do
  @moduledoc """
  Consumes events from Amazon SQS/SNS and converts them to email logs.
  """

  alias Passwordless.Email
  alias Passwordless.EventQueue.Message
  alias Passwordless.EventQueue.Source

  def start_link(%Message{data: data, source: %Source{} = source} = message) do
    Task.start_link(fn ->
      Email.create_message_from_event(data)
      Message.ack(message)
    end)
  end
end
