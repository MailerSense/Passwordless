defmodule Passwordless.MagicLink do
  @moduledoc """
  A magic link.
  """

  use Passwordless.Schema, prefix: "mgclnk"

  alias Passwordless.EmailMessage
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 16

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :expires_at,
      :accepted_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "magic_links" do
    field :key, Passwordless.EncryptedBinary, redact: true
    field :key_hash, Passwordless.HashedBinary, redact: true
    field :expires_at, :utc_datetime_usec
    field :accepted_at, :utc_datetime_usec

    belongs_to :email_message, EmailMessage

    timestamps()
  end

  @fields ~w(
    key
    expires_at
    accepted_at
    email_message_id
  )a
  @required_fields @fields -- [:accepted_at, :email_message_id]

  def changeset(%__MODULE__{} = magic_link, attrs \\ %{}, opts \\ []) do
    magic_link
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_key()
    |> put_hash_fields()
    |> validate_key_hash()
    |> assoc_constraint(:email_message)
    |> unique_constraint(:email_message_id)
    |> unsafe_validate_unique(:email_message_id, Passwordless.Repo, opts)
  end

  def generate_key do
    raw = :crypto.strong_rand_bytes(@size)
    signed = Token.sign(Endpoint, key_salt(), raw)
    {raw, signed}
  end

  # Private

  defp validate_key(changeset) do
    validate_length(changeset, :key, is: @size, count: :bytes)
  end

  defp validate_key_hash(changeset) do
    validate_required(changeset, :key_hash)
  end

  @hashed_fields [key_hash: :key]

  def put_hash_fields(changeset) do
    Enum.reduce(@hashed_fields, changeset, fn {hashed_field, unhashed_field}, changeset ->
      if value = get_field(changeset, unhashed_field) do
        put_change(changeset, hashed_field, value)
      else
        changeset
      end
    end)
  end

  defp verify_key(token) when is_binary(token) do
    Token.verify(Endpoint, key_salt(), token)
  end

  defp key_salt, do: Endpoint.config(:secret_key_base)
end
