defmodule Passwordless.BackgroundTask do
  @moduledoc """
  Run a function in a separate process parallel to the current one. Useful for things that take a bit of time but you want to send a response back quickly.
  """

  @timeout :timer.seconds(10)

  def run(f) do
    if Passwordless.config(:env) != :test || Passwordless.config(:force_async_background_task) do
      # Docs: https://hexdocs.pm/elixir/Task.html#module-dynamically-supervised-tasks
      Task.Supervisor.start_child(
        __MODULE__,
        fn ->
          Process.flag(:trap_exit, true)

          f.()
        end,
        restart: :transient,
        shutdown: @timeout
      )
    else
      f.()
    end
  end
end
