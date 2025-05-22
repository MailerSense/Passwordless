defmodule Passwordless.MagicLinkMapping do
  @moduledoc """
  A magic link mapping.
  """

  use Passwordless.Schema, prefix: "magic_link_mapping"

  import Ecto.Query

  alias Passwordless.App
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 16

  schema "magic_link_mappings" do
    field :key, Passwordless.EncryptedBinary, redact: true
    field :key_hash, Passwordless.HashedBinary, redact: true
    field :magic_link_id, :binary_id

    belongs_to :app, App

    timestamps(updated_at: false)
  end

  @doc """
  Get by signed token.
  """
  def get_by_token(query \\ __MODULE__, token_signed) when is_binary(token_signed) do
    with {:ok, token} <- verify_token(token_signed) do
      {:ok, from(q in query, where: q.key_hash == ^token and q.key == ^token)}
    end
  end

  @doc """
  Sign the token.
  """
  def sign_token(%__MODULE__{key: key}) when is_binary(key) do
    Token.sign(Endpoint, key_salt(), key)
  end

  @doc """
  Generate an underlying key.
  """
  def generate_key do
    :crypto.strong_rand_bytes(@size)
  end

  @fields ~w(
    key
    magic_link_id
    app_id
  )a
  @required_fields @fields

  @doc """
  A message mapping changeset.
  """
  def changeset(%__MODULE__{} = magic_link_mapping, attrs \\ %{}) do
    magic_link_mapping
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_key()
    |> put_hash_fields()
    |> validate_key_hash()
    |> validate_magic_link_id()
    |> assoc_constraint(:app)
  end

  # Private

  defp validate_key(changeset) do
    validate_length(changeset, :key, is: @size, count: :bytes)
  end

  defp validate_key_hash(changeset) do
    changeset
    |> validate_required(:key_hash)
    |> unique_constraint(:key_hash)
    |> unsafe_validate_unique(:key_hash, Passwordless.Repo)
  end

  defp validate_magic_link_id(changeset) do
    changeset
    |> unique_constraint(:magic_link_id)
    |> unsafe_validate_unique(:magic_link_id, Passwordless.Repo)
  end

  @hashed_fields [key_hash: :key]

  defp put_hash_fields(changeset) do
    Enum.reduce(@hashed_fields, changeset, fn {hashed_field, unhashed_field}, changeset ->
      if value = get_field(changeset, unhashed_field) do
        put_change(changeset, hashed_field, value)
      else
        changeset
      end
    end)
  end

  defp verify_token(token) when is_binary(token) do
    Token.verify(Endpoint, key_salt(), token)
  end

  defp key_salt, do: Endpoint.config(:secret_key_base)
end
