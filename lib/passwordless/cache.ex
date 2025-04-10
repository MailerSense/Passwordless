defmodule Passwordless.Cache do
  @moduledoc """
  API for caching objects across the application.
  """

  use Supervisor

  @cache Application.compile_env!(:passwordless, :cache)
  @adapter Keyword.fetch!(@cache, :adapter)

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    in_memory_cache = [
      %{
        id: __MODULE__.InMemory.name(),
        start: {Cachex, :start_link, [__MODULE__.InMemory.name(), []]}
      }
    ]

    children =
      case @adapter do
        __MODULE__.InMemory ->
          in_memory_cache

        __MODULE__.Redis ->
          redis = Passwordless.config(:redis)
          [{__MODULE__.Redix, redis_config(redis)} | in_memory_cache]

        _ ->
          raise ArgumentError, "Unknown cache adapter: #{@adapter}"
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  defdelegate get(key), to: @adapter
  defdelegate put(key, value, opts), to: @adapter
  defdelegate delete(key), to: @adapter
  defdelegate push(key, value), to: @adapter
  defdelegate pop(key), to: @adapter
  defdelegate exists?(key), to: @adapter

  def with(key, producer, opts) do
    case get(key) do
      nil ->
        value = producer.()
        put(key, value, opts)
        value

      value ->
        value
    end
  end

  # Private

  defp redis_config(redis) do
    [
      ssl: true,
      host: Keyword.fetch!(redis, :host),
      port: String.to_integer(Keyword.fetch!(redis, :port)),
      password: Keyword.fetch!(redis, :auth_token),
      socket_opts: [
        customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]
      ]
    ]
  end
end
