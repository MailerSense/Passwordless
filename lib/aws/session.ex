defmodule AWS.Session do
  @moduledoc """
  Represents a session with AWS or other cloud provider.
  """

  @client_defaults [
    http_client: {Passwordless.AWSClient, []}
  ]

  @doc """
  Get the AWS configuration.
  """
  def get do
    :s3
    |> ExAws.Config.new()
    |> Map.take([:region, :access_key_id, :secret_access_key, :security_token])
    |> Keyword.new()
  end

  @doc """
  Get the AWS client.
  """
  def get_client! do
    struct!(AWS.Client, Keyword.merge(@client_defaults, get()))
  end
end
