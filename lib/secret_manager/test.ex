defmodule SecretManager.Test do
  @moduledoc """
  Provides a local machine secret manager.
  """

  @behaviour SecretManager.Behaviour

  import Util.Persistent

  @impl true
  def get(secret_name, _opts \\ []) do
    value = Jason.encode!(%{CLOAK_KEY: cloak_key()})
    {:ok, {:secret, secret_name, value}}
  end

  @impl true
  def store(_secret, _opts \\ []) do
    {:error, :not_found}
  end

  defpersistent(cloak_key: test_cloak_key())

  def test_cloak_key do
    32 |> :crypto.strong_rand_bytes() |> Base.encode64()
  end
end
