defmodule Passwordless.AWS.Session do
  @moduledoc """
  Represents a session with AWS or other cloud provider.
  """

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
    %{
      region: region,
      access_key_id: access_key_id,
      secret_access_key: secret_access_key,
      security_token: token
    } = ExAws.Config.new(:s3)

    access_key_id
    |> AWS.Client.create(secret_access_key, token, region)
    |> AWS.Client.put_http_client({Passwordless.AWSClient, []})
  end
end
