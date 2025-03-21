defmodule SecretManager.Local do
  @moduledoc """
  Provides a local machine secret manager.
  """

  @behaviour SecretManager.Behaviour

  @impl true
  def get(secret_name, _opts \\ []) do
    {:ok, {:secret, secret_name, Jason.encode!(%{key: "value"})}}
  end

  @impl true
  def store(_secret, _opts \\ []) do
    {:error, :not_found}
  end
end
