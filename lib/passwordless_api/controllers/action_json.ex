defmodule PasswordlessApi.ActionJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.Action

  def new(%{action: %Action{} = action}) do
    %{action: action}
  end

  def show(%{action: %Action{} = action}) do
    %{action: action}
  end

  def update(%{action: %Action{} = action}) do
    %{action: action}
  end
end
