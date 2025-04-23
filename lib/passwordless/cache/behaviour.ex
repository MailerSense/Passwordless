defmodule Passwordless.Cache.Behaviour do
  @moduledoc """
  Defines the contract for entity permission management
  """

  @type key :: binary() | atom() | tuple()
  @type response :: any() | nil
  @type opts :: [ttl: non_neg_integer()]

  @doc """
  Get the stored value under a key
  """
  @callback get(key :: key()) :: response()

  @doc """
  Persist a value under a key
  """
  @callback put(key :: key(), value :: any(), opts :: opts()) :: response()

  @doc """
  Delete a value under a key
  """
  @callback delete(key :: key()) :: :ok

  @doc """
  Pushes a value into a queue
  """
  @callback push(key :: key(), value :: any()) :: response()

  @doc """
  Pops a value off a queue
  """
  @callback pop(key :: key()) :: response()

  @doc """
  Checks if a key exists
  """
  @callback exists?(key :: key()) :: boolean()
end
