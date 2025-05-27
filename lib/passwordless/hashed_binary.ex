defmodule Passwordless.HashedBinary do
  @moduledoc """
  Produces and stores a hash of the provided binary.
  """

  use Cloak.Ecto.HMAC, otp_app: :passwordless

  alias Passwordless.SecretManager.Vault

  @impl Cloak.Ecto.HMAC
  def init(config) do
    config =
      Keyword.merge(config,
        algorithm: :sha512,
        secret: Vault.get("CLOAK_HMAC_SECRET")
      )

    {:ok, config}
  end
end
