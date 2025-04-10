defmodule Passwordless.AWS.Lambda.Monitor.Server do
  @moduledoc false
  use GenServer

  alias Passwordless.AWS.Lambda.Monitor.State

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # API

  def watch(process) when is_pid(process) do
    GenServer.call(__MODULE__, {:watch, process})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  def started(id) do
    GenServer.call(__MODULE__, {:start_invocation, id})
  end

  # Server

  @impl true
  def init(_state) do
    {:ok, State.initial()}
  end

  @impl true
  def handle_call({:watch, pid}, _from, state) do
    Process.monitor(pid)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:start_invocation, id}, _from, state) do
    {:reply, :ok, State.start_invocation(state, id)}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, State.initial()}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, _state) do
    {:noreply, State.initial()}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    State.error(state, reason)
    {:noreply, State.initial()}
  end
end
