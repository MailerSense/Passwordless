defmodule SecretManager.Amazon do
  @moduledoc """
  Provides a AWS SecretsManager.
  """

  @behaviour SecretManager.Behaviour

  alias ExAws.SecretsManager

  @impl true
  def get(secret_name, _opts \\ []) when is_binary(secret_name) do
    {:ok, {:secret, secret_name, secret_name |> SecretsManager.get_secret_value() |> ExAws.request()}}
  end

  @impl true
  def store({:secret, name, content}, _opts \\ []) when is_binary(name) and is_binary(content) do
    :ok
  end
end
