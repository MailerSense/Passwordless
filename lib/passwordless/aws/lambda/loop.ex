defmodule Passwordless.AWS.Lambda.Loop do
  @moduledoc """
  The main Runtime loop process.

  This Process is responsible for polling the Lambda Runtime Service for
  function invocations and invoking the user's code. If this process crashes
  then the Monitor will report the error and stacktrace automatically.
  """

  use GenServer

  alias Passwordless.AWS.Lambda.Client
  alias Passwordless.AWS.Lambda.Loop.Handler
  alias Passwordless.AWS.Lambda.Monitor.Server

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    Server.watch(self())
    Process.send_after(self(), :process, :timer.seconds(1))
    {:ok, Handler.new(Passwordless.Release, :migrate_lambda)}
  end

  @impl true
  def handle_info(:process, handler) do
    Server.reset()
    process(Client.next_invocation(), handler)
    Process.send_after(self(), :process, :timer.seconds(1))
    {:noreply, handler}
  end

  # Private

  defp process(:no_invocation, _handler) do
    Logger.debug("no invocation to process")
  end

  defp process({id, body, context} = invocation, handler) do
    Server.started(id)
    Logger.info("handle invocation #{inspect(invocation)}")

    response =
      handler
      |> Handler.invoke(Jason.decode!(body), context)
      |> Jason.encode!()

    Client.complete_invocation(id, response)
  end
end
