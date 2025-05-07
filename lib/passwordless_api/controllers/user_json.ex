defmodule PasswordlessApi.UserJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.User

  def get(%{user: %User{} = user}) do
    %{user: user}
  end
end
