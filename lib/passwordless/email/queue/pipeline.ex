defmodule Passwordless.Email.Queue.Pipeline do
  @moduledoc """
  A pipeline for consuming and processing events from Amazon SQS/SNS.
  """

  use Supervisor

  alias Passwordless.Email.Queue.ConsumerManager
  alias Passwordless.Email.Queue.Deduplicator
  alias Passwordless.Email.Queue.Producer
  alias Passwordless.Email.Queue.Source

  @registry Passwordless.Email.Queue.Registry

  def start_link(%Source{} = source) do
    Supervisor.start_link(__MODULE__, source, name: via(source.id))
  end

  @impl true
  def init(%Source{} = source) do
    producers =
      for index <- 1..10,
          do: Supervisor.child_spec({Producer, [source, index]}, id: "producer_#{source.id}#{index}")

    children =
      producers ++
        [
          {Deduplicator, source},
          {ConsumerManager, source}
        ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def via(source_id) when is_binary(source_id) do
    {:via, Registry, {@registry, {__MODULE__, source_id}}}
  end
end
