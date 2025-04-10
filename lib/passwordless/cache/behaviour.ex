defmodule Passwordless.Cache.Behaviour do
  @moduledoc """
  Defines the contract for entity permission management
  """

  @type response :: any() | nil
  @type opts :: [ttl: non_neg_integer()]

  @doc """
  Get the stored value under a key
  """
  @callback get(key :: binary()) :: response()

  @doc """
  Persist a value under a key
  """
  @callback put(key :: binary(), value :: any(), opts :: opts()) :: response()

  @doc """
  Delete a value under a key
  """
  @callback delete(key :: binary()) :: :ok

  @doc """
  Pushes a value into a queue
  """
  @callback push(key :: binary(), value :: any()) :: response()

  @doc """
  Pops a value off a queue
  """
  @callback pop(key :: binary()) :: response()

  @doc """
  Checks if a key exists
  """
  @callback exists?(key :: binary()) :: boolean()
end
