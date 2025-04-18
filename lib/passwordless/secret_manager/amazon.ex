defmodule Passwordless.SecretManager.Amazon do
  @moduledoc """
  Provides a AWS SecretsManager.
  """

  @behaviour Passwordless.SecretManager.Behaviour

  alias ExAws.SecretsManager

  @impl true
  def get(secret_name, _opts \\ []) when is_binary(secret_name) do
    case secret_name
         |> SecretsManager.get_secret_value()
         |> ExAws.request() do
      {:ok, %{"SecretString" => secret_string}} ->
        {:ok, {:secret, secret_name, secret_string}}

      response ->
        {:error, "failed to fetch secret #{secret_name}: #{inspect(response)}"}
    end
  end

  @impl true
  def store({:secret, name, content}, _opts \\ []) when is_binary(name) and is_binary(content) do
    :ok
  end
end
