defmodule Passwordless.EmailUnsubscribeLinkMapping do
  @moduledoc """
  An email unsubscribe link mapping.
  """

  use Passwordless.Schema, prefix: "email_unsubscribe_link_mapping"

  import Ecto.Changeset
  import Ecto.Query

  alias Passwordless.App
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 16

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :email_id,
      :inserted_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "email_unsubscribe_link_mappings" do
    field :key, Passwordless.EncryptedBinary, redact: true
    field :key_hash, Passwordless.HashedBinary, redact: true
    field :email_id, :binary_id

    belongs_to :app, App

    timestamps(updated_at: false)
  end

  @fields ~w(key email_id app_id)a
  @required_fields @fields

  @doc """
  A mapping changeset.
  """
  def changeset(%__MODULE__{} = email_unsubscribe_link, attrs \\ %{}) do
    email_unsubscribe_link
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> decode_email_id()
    |> validate_key()
    |> put_hash_fields()
    |> validate_key_hash()
    |> unique_constraint(:email_id)
    |> assoc_constraint(:app)
  end

  @doc """
  Get the mapping by signed token.
  """
  def get_by_token(token_signed) when is_binary(token_signed) do
    with {:ok, token} <- verify_token(token_signed) do
      {:ok,
       from(
         m in __MODULE__,
         where: m.key_hash == ^token,
         left_join: a in assoc(m, :app),
         select: {m, a}
       )}
    end
  end

  @doc """
  Sign the mapping token.
  """
  def sign_token(%__MODULE__{key: key}) when is_binary(key) do
    Token.sign(Endpoint, key_salt(), key)
  end

  @doc """
  Generate a random key.
  """
  def generate_key do
    :crypto.strong_rand_bytes(@size)
  end

  # Private

  defp decode_email_id(changeset) do
    update_change(changeset, :email_id, fn email_id ->
      case Database.PrefixedUUID.slug_to_uuid(email_id) do
        {:ok, _prefix, uuid} -> uuid
        _ -> email_id
      end
    end)
  end

  defp validate_key(changeset) do
    validate_length(changeset, :key, is: @size, count: :bytes)
  end

  defp validate_key_hash(changeset) do
    changeset
    |> validate_required(:key_hash)
    |> unique_constraint(:key_hash)
    |> unsafe_validate_unique(:key_hash, Passwordless.Repo)
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
