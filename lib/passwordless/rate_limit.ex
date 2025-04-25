defmodule Passwordless.RateLimit do
  @moduledoc false

  use Supervisor

  @rate_limit Application.compile_env!(:passwordless, :rate_limit)
  @adapter Keyword.fetch!(@rate_limit, :adapter)

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    opts =
      case @adapter do
        __MODULE__.ETS ->
          Passwordless.config([:hammer, :ets])

        __MODULE__.Redis ->
          Passwordless.config([:hammer, :redis])

        _ ->
          raise ArgumentError, "Unknown rate limit adapter: #{@adapter}"
      end

    children = [
      {@adapter, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defdelegate get(key, scale), to: @adapter
  defdelegate hit(key, scale, limit), to: @adapter
  defdelegate hit(key, scale, limit, increment), to: @adapter
end
