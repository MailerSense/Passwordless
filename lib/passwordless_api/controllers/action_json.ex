defmodule PasswordlessApi.ActionJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.Action

  def get(%{action: %Action{} = action}) do
    %{action: action}
  end

  def authenticate(%{action: %Action{} = action}) do
    %{action: action}
  end
end
