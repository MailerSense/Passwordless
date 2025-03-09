defmodule Passwordless.Formatter do
  @moduledoc false

  def format!(code, language) when language in [:javascript, :typescript, :html] do
    Passwordless.Native.format_code(code, language)
  end

  def format!(code, :json) when is_map(code) do
    Jason.encode!(code, pretty: true)
  end

  def format!(code, :json) when is_binary(code) do
    code
  end
end
