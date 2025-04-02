defmodule Passwordless.Vault do
  @moduledoc """
  A vault.
  """

  use Cloak.Vault, otp_app: :passwordless

  alias Passwordless.SecretVault

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers, default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: decode_env!("CLOAK_KEY")})

    {:ok, config}
  end

  defp decode_env!(var) do
    var
    |> SecretVault.get()
    |> Base.decode64!()
  end
end
