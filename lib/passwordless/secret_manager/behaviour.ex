defmodule Passwordless.SecretManager.Behaviour do
  @moduledoc """
  Defines the contract for a secret manager system.
  """

  @typedoc """
  Represents a secret - {:secret, name, content}
  """
  @type secret :: {:secret, binary(), binary()}
  @type secret_name :: binary()
  @type secret_opts :: [project: binary(), version: binary()]

  @callback get(secret_name :: binary(), opts :: secret_opts()) :: {:ok, secret()} | {:error, any()}
  @callback store(secret :: secret(), opts :: secret_opts()) :: :ok | {:error, any()}
end
