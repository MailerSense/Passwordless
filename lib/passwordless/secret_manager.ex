defmodule Passwordless.SecretManager do
  @moduledoc """
  This module is used to store and retrieve secrets.
  """

  @secret_manager Application.compile_env!(:passwordless, :secret_manager)
  @adapter Keyword.fetch!(@secret_manager, :adapter)

  @doc """
  Delegate operations to the configured adapter.
  """
  defdelegate get(secret_name, opts \\ []), to: @adapter
  defdelegate store(secret, opts \\ []), to: @adapter
end
