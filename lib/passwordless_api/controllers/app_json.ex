defmodule PasswordlessApi.AppJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.App

  def index(%{app: %App{} = app}) do
    %{app: app}
  end
end
