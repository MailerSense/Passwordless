defmodule Passwordless.Storage.Behaviour do
  @moduledoc """
  Defines the contract for an object storage.
  """

  @typedoc """
  Represents a file - {:file, name, mime, content}
  """
  @type file :: {:file, binary(), binary(), binary()}
  @type bucket :: binary()
  @type path :: binary()

  @callback get(bucket :: binary(), path :: binary()) :: {:ok, file()} | :not_found
  @callback list(bucket :: binary(), opts :: keyword()) :: Enumerable.t()
  @callback upload(bucket :: binary(), path :: binary(), file :: file()) :: {:ok, path()} | {:error, any()}
  @callback delete(bucket :: binary(), path :: binary()) :: :ok | :not_found
  @callback generate_signed_url(bucket :: binary(), path :: binary(), opts :: keyword()) ::
              {:ok, path()} | {:error, any()}
end
