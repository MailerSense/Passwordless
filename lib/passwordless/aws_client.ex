defmodule Passwordless.AWSClient do
  @moduledoc """
  The Elixir-AWS HTTP client implemented with Finch (our go-to HTTP client).
  """

  @behaviour AWS.HTTPClient

  @finch Passwordless.Finch.AWS
  @max_attempts 5

  @impl true
  def request(method, url, body, headers, options) do
    do_request(method, url, body, headers, options, {:attempt, 1})
  end

  # Private

  defp do_request(_method, _url, _body, _headers, _options, {:give_up, result}) do
    result
  end

  defp do_request(method, url, body, headers, options, {:attempt, attempt}) when attempt > 0 do
    url = IO.iodata_to_binary(url)
    request = Finch.build(method, url, headers, body)

    case Finch.request(request, @finch, options) do
      {:ok, %Finch.Response{status: status, headers: headers, body: body}} when status in 200..299 or status == 304 ->
        {:ok, %{status_code: status, body: body, headers: headers}}

      {:ok, %Finch.Response{status: status} = resp} = result when status in 400..499 ->
        if retryable?(resp) do
          do_request(
            method,
            url,
            body,
            headers,
            options,
            attempt_again?(attempt, result)
          )
        else
          result
        end

      {:ok, %Finch.Response{status: status}} when status >= 500 ->
        do_request(
          method,
          url,
          body,
          headers,
          options,
          attempt_again?(attempt, {:error, :internal_server_error})
        )

      {:error, _reason} = error ->
        error
    end
  end

  defp retryable?(%Finch.Response{body: body}) do
    case Jason.decode(body) do
      {:ok, %{"__type" => error_type}} when is_binary(error_type) ->
        error_retryable?(error_type)

      _ ->
        false
    end
  end

  @retryable_errors ~w(
    Throttling
    ThrottlingException
    ThrottledException
    RequestThrottledException
    TooManyRequestsException
    ProvisionedThroughputExceededException
    TransactionInProgressException
    RequestLimitExceeded
    BandwidthLimitExceeded
    LimitExceededException
    RequestThrottled
    SlowDown
  )

  defp error_retryable?(error_type) when is_binary(error_type) do
    error_type
    |> String.split("#")
    |> case do
      [_, type] when type in @retryable_errors -> true
      [type] when type in @retryable_errors -> true
      _ -> false
    end
  end

  defp error_retryable?(_), do: false

  defp attempt_again?(attempt, result) when attempt > 0 do
    if attempt >= @max_attempts do
      {:give_up, result}
    else
      attempt |> backoff() |> :timer.sleep()
      {:attempt, attempt + 1}
    end
  end

  defp backoff(attempt) when attempt > 0 do
    trunc(:math.pow(attempt, 4) + :timer.seconds(1) + :rand.uniform(500) * attempt)
  end
end
