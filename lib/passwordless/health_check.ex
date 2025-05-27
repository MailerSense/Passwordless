defmodule Passwordless.HealthCheck do
  @moduledoc """
  Responsible for doing the health checks
  and returning the result to the caller
  """

  use GenServer

  import SqlFmt.Helpers

  @table :health_checks
  @tick_interval :timer.seconds(5)

  defmodule State do
    @moduledoc """
    Internal state
    """

    use TypedStruct

    typedstruct do
      field :ready, list((-> :ok | {:error, any()})), enforce: true
      field :live, list((-> :ok | {:error, any()})), enforce: true
    end
  end

  def start_link({_ready, _live} = state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Add a readiness check
  """
  def add_readiness(check) when is_function(check, 0) do
    GenServer.cast(__MODULE__, {:add_readiness, check})
  end

  @doc """
  Add a liveness check
  """
  def add_liveness(check) when is_function(check, 0) do
    GenServer.cast(__MODULE__, {:add_liveness, check})
  end

  @doc """
  Execute readiness checks
  """
  def check_readiness, do: get_result(:readiness)

  @doc """
  Execute liness checks
  """
  def check_liveness, do: get_result(:liveness)

  # Server

  @impl true
  def init({ready, live}) do
    if :ets.info(@table) == :undefined do
      :ets.new(@table, [
        :set,
        :named_table,
        :protected,
        read_concurrency: true,
        write_concurrency: false
      ])
    end

    tick()

    {:ok, %State{ready: ready, live: live}}
  end

  @impl true
  def handle_cast({:add_readiness, check}, %State{ready: ready} = state) do
    {:noreply, %State{state | ready: [check | ready]}}
  end

  @impl true
  def handle_cast({:add_liveness, check}, %State{live: live} = state) do
    {:noreply, %State{state | ready: [check | live]}}
  end

  @impl true
  def handle_info(:tick, %State{ready: ready, live: live} = state) do
    put_result(:readiness, all_pass?(ready))
    put_result(:liveness, all_pass?(live))

    tick()

    {:noreply, state}
  end

  # Common checks

  @doc """
  Pings the Ecto `repo` to check if connection is healthy.

  Returns `:ok` or `{:error, "reason"}`.

  ## Examples

      iex> HealthCheck.repo?(MyRepo)
      :ok

  """
  def repo?(repo) do
    fn ->
      result =
        try do
          Ecto.Adapters.SQL.query(repo, ~SQL"SELECT 1")
        rescue
          e in DBConnection.ConnectionError -> e
        end

      case result do
        {:ok, _} -> :ok
        {:error, _} -> {:error, :database_query_failed}
      end
    end
  end

  @doc """
  Checks if PID returned by `pid_fun` references a living process.

  Returns `:ok` or `{:error, "reason"}`.

  ## Examples

      iex> HealthCheck.alive?(&give_pid/0)
      :ok

  """
  def alive?(pid_fun) do
    fn ->
      case pid_fun.() do
        pid when is_pid(pid) ->
          if Process.alive?(pid) do
            :ok
          else
            {:error, :process_died}
          end

        _ ->
          {:error, :process_died}
      end
    end
  end

  # Private

  defp tick, do: Process.send_after(self(), :tick, @tick_interval)

  defp all_pass?(checks) do
    checks
    |> Task.async_stream(& &1.())
    |> Enum.reduce_while(:ok, fn
      {:ok, :ok}, _ -> {:cont, :ok}
      {:ok, err}, _ -> {:halt, err}
    end)
  end

  defp get_result(kind) when kind in [:readiness, :liveness] do
    key = {__MODULE__, kind}

    case :ets.lookup(@table, key) do
      [{^key, value}] -> value
      _ -> :initializing
    end
  end

  defp put_result(kind, value) when kind in [:readiness, :liveness], do: :ets.insert(@table, {{__MODULE__, kind}, value})
end
