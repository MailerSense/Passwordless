defmodule PasswordlessApi.ActionJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.Action

  def show(%{action: %Action{} = action}) do
    %{action: action}
  end

  def query(%{result: result}) do
    %{result: result}
  end

  def authenticate(%{action: %Action{} = action}) do
    %{action: action}
  end
end
