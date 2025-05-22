defmodule Passwordless.MagicLink do
  @moduledoc """
  A magic link.
  """

  use Passwordless.Schema, prefix: "magic_link"

  import Ecto.Query

  alias Passwordless.App
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

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, where: [app_id: ^app.id]
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
  Generate an underlying key.
  """
  def generate_key do
    :crypto.strong_rand_bytes(@size)
  end

  @doc """
  Sign the token.
  """
  def sign_token(%__MODULE__{key: key, expires_at: expires_at}) when is_binary(key) do
    max_age = DateTime.diff(expires_at, DateTime.utc_now(), :second)
    Token.sign(Endpoint, key_salt(), key, max_age: max_age)
  end

  @fields ~w(
    key
    expires_at
    accepted_at
    email_message_id
  )a
  @required_fields @fields -- [:accepted_at]

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

  # Private

  defp validate_key(changeset) do
    validate_length(changeset, :key, is: @size, count: :bytes)
  end

  defp validate_key_hash(changeset) do
    validate_required(changeset, :key_hash)
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
