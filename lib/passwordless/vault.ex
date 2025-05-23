defmodule Passwordless.Vault do
  @moduledoc """
  A vault for the Cloak library.
  """

  use Cloak.Vault, otp_app: :passwordless

  alias Passwordless.SecretManager.Vault

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers, default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: Vault.get("CLOAK_KEY")})

    {:ok, config}
  end
end
