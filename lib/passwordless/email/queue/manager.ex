defmodule Passwordless.Email.Queue.Manager do
  @moduledoc """
  Manages the lifecycle of event processing pipelines.
  """

  use Supervisor

  alias Passwordless.Email.Queue.Monitor
  alias Passwordless.Email.Queue.PipelineManager
  alias Passwordless.Email.Queue.Source

  require Logger

  @registry Passwordless.Email.Queue.Registry
  @queues Application.compile_env!(:passwordless, :queues)

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Registry, keys: :unique, name: @registry},
      {Monitor, []},
      {PipelineManager, []},
      {Agent,
       fn ->
         if @env != :test && is_nil(System.get_env("DATABASE_MIGRATION")) do
           @queues
           |> Enum.map(fn {k, v} -> struct!(Source, Map.put(v, :id, k)) end)
           |> Enum.each(&start_pipeline/1)
         end
       end}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @doc """
  Delegate pipeline controls to the pipeline manager.
  """
  defdelegate start_pipeline(source), to: PipelineManager
  defdelegate restart_pipeline(source), to: PipelineManager
  defdelegate terminate_pipeline(source), to: PipelineManager
end
