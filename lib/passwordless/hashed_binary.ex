defmodule Passwordless.HashedBinary do
  @moduledoc false
  use Cloak.Ecto.HMAC, otp_app: :passwordless

  alias Passwordless.SecretVault

  @impl Cloak.Ecto.HMAC
  def init(config) do
    config =
      Keyword.merge(config,
        algorithm: :sha512,
        secret: SecretVault.get("CLOAK_HMAC_SECRET")
      )

    {:ok, config}
  end
end
