defmodule Passwordless.AWS.Lambda.Monitor.State do
  @moduledoc false
  alias Passwordless.AWS.Lambda.Client
  alias Passwordless.AWS.Lambda.Monitor.Error

  @doc "the monitor's initial state"
  def initial do
    :not_started
  end

  @doc "start processing an invocation"
  def start_invocation(:not_started, invocation_id) do
    {:in_progress, invocation_id}
  end

  @doc "report an error before an invocation was started"
  def error(:not_started, reason) do
    :runtime
    |> Error.from_exit_reason(reason)
    |> Jason.encode!()
    |> Client.init_error()
  end

  def error({:in_progress, id}, reason) do
    :function
    |> Error.from_exit_reason(reason)
    |> Jason.encode!()
    |> Client.invocation_error(id)
  end
end
