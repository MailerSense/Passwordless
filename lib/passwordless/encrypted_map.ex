defmodule Passwordless.EncryptedMap do
  @moduledoc """
  Encrypted map.
  """

  use Cloak.Ecto.Map, vault: Passwordless.Vault
end
