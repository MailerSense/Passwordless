defmodule PasswordlessApi.AppClientJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.App

  def index(%{app: %App{} = app}) do
    %{app: %{name: app.name}}
  end
end
