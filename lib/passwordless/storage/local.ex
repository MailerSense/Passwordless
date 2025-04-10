defmodule Passwordless.Storage.Local do
  @moduledoc """
  Provides an implementation of the Storage behaviour for local filesystem.
  """

  @behaviour Passwordless.Storage.Behaviour

  @impl true
  def upload(bucket, _path, {:file, _name, _mime, _content}) when is_binary(bucket) do
    {:ok, "https://placehold.co/200"}
  end

  @impl true
  def get(bucket, path) when is_binary(bucket) and is_binary(path) do
    {:ok, {:file, "file.txt", "text/plain", "content"}}
  end

  @impl true
  def list(bucket, _opts) when is_binary(bucket) do
    []
  end

  @impl true
  def delete(_bucket, _path) do
    :ok
  end

  @impl true
  def generate_signed_url(bucket, file, _opts) when is_binary(bucket) and is_binary(file) do
    {:ok, "https://placehold.co/200"}
  end
end
