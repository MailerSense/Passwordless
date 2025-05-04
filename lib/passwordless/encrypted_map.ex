defmodule Passwordless.EncryptedMap do
  @moduledoc """
  Encrypted map.
  """

  use Cloak.Ecto.Map, vault: Passwordless.Vault

  @impl Ecto.Type
  def embed_as(:json), do: :dump

  @impl Ecto.Type
  def embed_as(_format), do: :self
end
