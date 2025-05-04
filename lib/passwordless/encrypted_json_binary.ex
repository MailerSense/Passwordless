defmodule Passwordless.EncryptedJSONBinary do
  @moduledoc """
  Encrypted binary.
  """

  use Cloak.Ecto.Binary, vault: Passwordless.Vault

  def embed_as(:json), do: :dump

  def dump(nil), do: {:ok, nil}

  def dump(value) do
    with {:ok, encrypted} <- super(value) do
      {:ok, Base.encode64(encrypted)}
    end
  end

  def load(nil), do: {:ok, nil}

  def load(value), do: super(Base.decode64!(value))
end
