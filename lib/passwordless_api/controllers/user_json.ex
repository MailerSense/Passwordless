defmodule PasswordlessApi.UserJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.User

  def show(%{user: %User{} = user}) do
    %{user: user}
  end
end
