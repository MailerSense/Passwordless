defmodule Passwordless.EventQueue.Pipeline do
  @moduledoc """
  A pipeline for consuming and processing events from Amazon SQS/SNS.
  """

  use Supervisor

  alias Passwordless.EventQueue.ConsumerManager
  alias Passwordless.EventQueue.Deduplicator
  alias Passwordless.EventQueue.Producer
  alias Passwordless.EventQueue.Source

  @registry Passwordless.EventQueue.Registry

  def start_link(%Source{} = source) do
    Supervisor.start_link(__MODULE__, source, name: via(source.id))
  end

  @impl true
  def init(%Source{} = source) do
    producers =
      for index <- Source.consumers(),
          do: Supervisor.child_spec({Producer, [source, index]}, id: "producer_#{source.id}_#{index}")

    children =
      producers ++
        [
          {Deduplicator, source},
          {ConsumerManager, source}
        ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def via(source_id) do
    {:via, Registry, {@registry, {__MODULE__, source_id}}}
  end
end
