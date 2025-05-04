defmodule Passwordless.EncryptedBinary do
  @moduledoc """
  Encrypted binary.
  """

  use Cloak.Ecto.Binary, vault: Passwordless.Vault
end
