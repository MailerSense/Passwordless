defmodule Passwordless.EncryptedBinary do
  @moduledoc """
  Encrypted binary.
  """

  use Cloak.Ecto.Binary, vault: Passwordless.Vault

  @impl Ecto.Type
  def embed_as(:json), do: :dump

  @impl Ecto.Type
  def embed_as(_format), do: :self
end
