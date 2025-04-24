defmodule Passwordless.EventQueue.ConsumerManager do
  @moduledoc """
  Manages the lifecycle of event consumers.
  """

  use ConsumerSupervisor

  alias Passwordless.EventQueue.Consumer
  alias Passwordless.EventQueue.Deduplicator
  alias Passwordless.EventQueue.Source

  @registry Passwordless.EventQueue.Registry

  def start_link(%Source{} = source) do
    ConsumerSupervisor.start_link(__MODULE__, source, name: via(source.id))
  end

  @impl true
  def init(%Source{} = source) do
    children = [
      %{
        id: Consumer,
        start: {Consumer, :start_link, []},
        restart: :transient
      }
    ]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [
        {Deduplicator.via(source.id), []}
      ]
    ]

    {:ok, children, opts}
  end

  # Private

  defp via(source_id) do
    {:via, Registry, {@registry, {__MODULE__, source_id}}}
  end
end
