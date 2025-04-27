defmodule PasswordlessApi.AppJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.App

  def show(%{app: %App{} = app}) do
    %{app: app}
  end

  def authenticators(%{authenticators: authenticators}) do
    %{authenticators: Map.new(authenticators)}
  end
end
