defmodule SecretManager do
  @moduledoc """
  This module is used to store and retrieve secrets.
  """

  @secret Application.compile_env!(:passwordless, :secret_manager)
  @adapter Keyword.fetch!(@secret, :adapter)

  @doc """
  Delegate operations to the configured adapter.
  """
  defdelegate get(secret_name, opts \\ []), to: @adapter
  defdelegate store(secret, opts \\ []), to: @adapter
end
