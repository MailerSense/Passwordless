defmodule Passwordless.ObanHook do
  @moduledoc """
  A hook that sends exceptions to Sentry when an Oban job fails.
  """

  def after_process(state, job) when state in [:discard, :error] do
    error = job.unsaved_error
    extra = Map.take(job, [:attempt, :id, :args, :max_attempts, :meta, :queue, :worker])

    Sentry.capture_exception(error.reason, stacktrace: error.stacktrace, extra: extra)
  end

  def after_process(_state, _job), do: :ok
end

Oban.Pro.Worker.attach_hook(Passwordless.ObanHook)
