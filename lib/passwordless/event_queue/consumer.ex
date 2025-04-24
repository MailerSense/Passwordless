defmodule Passwordless.EventQueue.Consumer do
  @moduledoc """
  Consumes events from Amazon SQS/SNS and converts them to email logs.
  """

  alias Passwordless.Email.EventDecoder
  alias Passwordless.EventQueue.Message

  def start_link(%Message{data: data} = message) do
    Task.start_link(fn ->
      %{messsage: data}
      |> EventDecoder.new()
      |> Oban.insert!()

      Message.ack(message)
    end)
  end
end
