defmodule Passwordless.Storage.Amazon do
  @moduledoc """
  Provides an implementation of the Storage behaviour for Amazon S3.
  """

  @behaviour Passwordless.Storage.Behaviour

  alias ExAws.S3

  @doc """
  Upload a file to Google Storage bucket
  """
  @impl true
  def upload(bucket, path, {:file, name, _mime, content}) when is_binary(bucket) do
    path = Path.join(path, name)

    with {:ok, _response} <-
           bucket
           |> S3.put_object(path, content)
           |> ExAws.request() do
      {:ok, path}
    end
  end

  @doc """
  Get the object contained within a bucket.
  """
  @impl true
  def get(bucket, path) when is_binary(bucket) and is_binary(path) do
    case bucket |> S3.head_object(path) |> ExAws.request() do
      {:ok, %{headers: headers, status_code: 200}} when is_list(headers) ->
        content =
          bucket
          |> ExAws.S3.download_file(path, :memory)
          |> ExAws.stream!()
          |> Enum.to_list()

        headers = Map.new(headers)

        {:file, Path.basename(path), Map.get(headers, "Content-Type"), content}

      _ ->
        :not_found
    end
  end

  @doc """
  List the objects contained within a bucket.
  Represents the listing a stream to be exhaustively iterated.
  """
  @impl true
  def list(bucket, _opts \\ []) when is_binary(bucket) do
    bucket
    |> S3.list_objects()
    |> ExAws.stream!()
    |> Stream.map(fn %{key: key} -> key end)
  end

  @doc """
  Deletes the object.
  """
  @impl true
  def delete(bucket, path) do
    case bucket |> S3.delete_object(path) |> ExAws.request() do
      {:ok, _} -> :ok
      _ -> :not_found
    end
  end

  @signed_url_opts [
    expires_in: div(:timer.minutes(30), 1000)
  ]

  @doc """
  Generate a signed URL to a file store on a private bucket.
  The URL is valid for GET requests for up to 60 seconds after generation.
  """
  @impl true
  def generate_signed_url(bucket, path, opts \\ []) when is_binary(bucket) and is_binary(path) do
    :s3
    |> ExAws.Config.new()
    |> S3.presigned_url(:get, bucket, path, Keyword.merge(@signed_url_opts, opts || []))
  end
end
