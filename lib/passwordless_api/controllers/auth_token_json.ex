defmodule PasswordlessApi.AuthTokenJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.AuthToken

  def show(%{auth_token: %AuthToken{} = auth_token}) do
    %{permissions: auth_token.permissions}
  end
end
