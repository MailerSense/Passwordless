defmodule Passwordless.EventQueue.Manager do
  @moduledoc """
  Manages the lifecycle of event processing pipelines.
  """

  use Supervisor

  alias Passwordless.EventQueue.PipelineManager
  alias Passwordless.EventQueue.Source

  require Logger

  @registry Passwordless.EventQueue.Registry
  @env Application.compile_env!(:passwordless, :env)

  def start_link(queues) do
    Supervisor.start_link(__MODULE__, queues, name: __MODULE__)
  end

  @impl true
  def init(queues) do
    children = [
      {Registry, keys: :unique, name: @registry},
      {PipelineManager, []},
      {Agent,
       fn ->
         if @env != :test && is_nil(System.get_env("DATABASE_MIGRATION")) do
           queues
           |> Enum.map(&struct!(Source, &1))
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
