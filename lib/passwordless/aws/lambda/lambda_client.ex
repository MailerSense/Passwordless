defmodule Passwordless.AWS.Lambda.Client do
  @moduledoc """
  This module represents an HTTP client for the Lambda Runtime service.
  """

  use Tesla

  alias __MODULE__.Context

  require Logger

  plug Tesla.Middleware.BaseUrl, "http://#{service_endpoint()}/2018-06-01/runtime"
  plug Tesla.Middleware.Headers, [{"content-type", "text/plain"}]
  plug Tesla.Middleware.Logger

  defmodule Context do
    @moduledoc false
    @request_id "lambda-runtime-aws-request-id"
    @trace_id "lambda-runtime-trace-id"
    @client_context "x-amz-client-context"
    @cognito_identity "x-amz-cognito-identity"
    @deadline_ns "lambda-runtime-deadline-ms"
    @invoked_function_arn "lambda-runtime-invoked-function-arn"

    @known_headers [
      @request_id,
      @trace_id,
      @client_context,
      @cognito_identity,
      @deadline_ns,
      @invoked_function_arn
    ]

    def from_headers(headers) when is_list(headers) do
      headers
      |> Enum.map(fn {field, value} -> {String.downcase(to_string(field)), to_string(value)} end)
      |> Enum.filter(fn {field, _} -> field in @known_headers end)
      |> Map.new()
    end

    def request_id(context) when is_map(context) do
      context[@request_id]
    end
  end

  def service_endpoint do
    System.get_env("AWS_LAMBDA_RUNTIME_API")
  end

  def invocation_error(err_msg, id) do
    with {:ok, _response} <- post("/invocation/#{id}/error", err_msg) do
      :ok
    end
  end

  def init_error(err_msg) do
    with {:ok, _response} <- post("/init/error", err_msg) do
      :ok
    end
  end

  def complete_invocation(id, response) do
    with {:ok, _response} <- post("/invocation/#{id}/response", response) do
      :ok
    end
  end

  def next_invocation do
    case get("/invocation/next") do
      {:ok, %Tesla.Env{status: 200, headers: headers, body: body}} ->
        context = Context.from_headers(headers)
        {Context.request_id(context), body, context}

      {:error, reason} ->
        Logger.error("next_invocation failed with reason: #{inspect(reason)}")
        :no_invocation
    end
  end
end
