defmodule AWS.Lambda.Monitor.Error do
  @moduledoc """
  This module defines the Error struct which is used to communicate runtime
  errors to the Lambda Runtime Service.
  """

  @derive Jason.Encoder
  defstruct [
    :errorMessage,
    :errorType,
    :stackTrace
  ]

  def from_exit_reason(error_type, {error, stacktrace} = _reason) do
    exception = Exception.normalize(:error, error, stacktrace)
    build_error(error_name(error_type, exception), exception, stacktrace)
  end

  def from_exit_reason(error_type, reason) do
    exception = Exception.normalize(:error, {"unexpected exit", reason})
    build_error(error_name(error_type, exception), exception, [])
  end

  # Private

  defp error_name(:function, %{__struct__: name, __exception__: true}) do
    "Function#{name}"
  end

  defp error_name(:runtime, %{__struct__: name, __exception__: true}) do
    "Runtime#{name}"
  end

  defp error_name(:function, _) do
    "FunctionUnknownError"
  end

  defp error_name(:runtime, _) do
    "RuntimeUnknownError"
  end

  defp build_error(error_type, err, stacktrace) do
    %__MODULE__{
      errorMessage: Exception.format(:error, err),
      errorType: error_type,
      stackTrace: Enum.map(stacktrace, &Exception.format_stacktrace_entry/1)
    }
  end
end
