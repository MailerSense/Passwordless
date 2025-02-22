defmodule Passwordless.ExAwsClient do
  @moduledoc """
  The ExAws HTTP client implemented with Finch (our go-to HTTP client).
  """

  @behaviour ExAws.Request.HttpClient

  @finch Passwordless.Finch.AWS

  @impl true
  def request(method, url, body, headers, _http_opts) do
    request = Finch.build(method, url, headers, body)

    case Finch.request(request, @finch) do
      {:ok, %Finch.Response{status: status, headers: headers, body: body}} ->
        {:ok, %{status_code: status, body: body, headers: headers}}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end
end
