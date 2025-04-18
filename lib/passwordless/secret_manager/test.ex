defmodule Passwordless.SecretManager.Test do
  @moduledoc """
  Provides a local machine secret manager.
  """

  @behaviour Passwordless.SecretManager.Behaviour

  import Util.Persistent

  @impl true
  def get(secret_name, _opts \\ []) do
    value = Jason.encode!(%{CLOAK_KEY: cloak_key(), CLOAK_HMAC_SECRET: cloak_hmac_secret()})
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

  defpersistent(cloak_hmac_secret: test_cloak_hmac_secret())

  def test_cloak_hmac_secret do
    32 |> :crypto.strong_rand_bytes() |> Base.encode64()
  end
end
