defmodule Storage do
  @moduledoc """
  API for interacting with object storage.
  """

  @storage Application.compile_env!(:passwordless, :storage)
  @adapter Keyword.fetch!(@storage, :adapter)

  @doc """
  Delegate operations to the configured adapter.
  """
  defdelegate get(bucket, path), to: @adapter
  defdelegate list(bucket, opts \\ []), to: @adapter
  defdelegate upload(bucket, path, file), to: @adapter
  defdelegate delete(bucket, path), to: @adapter
  defdelegate generate_signed_url(bucket, path, opts \\ []), to: @adapter
end
