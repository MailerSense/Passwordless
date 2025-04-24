defmodule Passwordless.EventQueue.Consumer do
  @moduledoc """
  Consumes events from Amazon SQS/SNS and converts them to email logs.
  """

  alias Passwordless.Email.EventDecoder
  alias Passwordless.EventQueue.Message

  def start_link(%Message{data: data} = message) do
    Task.start_link(fn ->
      with %{"Message" => raw_message} <- data,
           {:ok, decoded} <- Jason.decode(raw_message),
           {:ok, _job} <- %{message: decoded} |> EventDecoder.new() |> Oban.insert(),
           do: :ok

      Message.ack(message)
    end)
  end
end
