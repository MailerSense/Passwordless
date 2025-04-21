defmodule PasswordlessApi.AuthTokenJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.AuthToken

  def show(%{auth_token: %AuthToken{} = auth_token}) do
    %{scopes: auth_token.scopes}
  end
end
