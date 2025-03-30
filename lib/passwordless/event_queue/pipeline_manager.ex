defmodule Passwordless.EventQueue.PipelineManager do
  @moduledoc """
  Dynamically spawns processing pipelines for events from Amazon SQS/SNS.
  """

  use DynamicSupervisor

  alias Passwordless.EventQueue.Pipeline
  alias Passwordless.EventQueue.Source

  @registry Passwordless.EventQueue.Registry

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a new pipeline with the given source, or errors out if it already exists.
  """
  def start_pipeline(%Source{} = source) do
    DynamicSupervisor.start_child(__MODULE__, {Pipeline, source})
  end

  @doc """
  Restarts a pipeline with the given source, or errors out if it does not exist.
  """
  def restart_pipeline(%Source{} = source) do
    with :ok <- terminate_pipeline(source) do
      start_pipeline(source)
    end
  end

  @doc """
  Terminates a pipeline with the given source, or errors out if it does not exist.
  """
  def terminate_pipeline(%Source{} = source) do
    with {:ok, pid} <- get_pipeline_pid(source) do
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  # Private

  defp get_pipeline_pid(%Source{} = source) do
    {:via, Registry, {@registry, key}} = Pipeline.via(source.id)

    case Registry.lookup(@registry, key) do
      [{pid, _}] when is_pid(pid) -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end
end
