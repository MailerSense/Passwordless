defmodule Passwordless.ChallengeToken do
  @moduledoc """
  A challenge token.
  """

  use Passwordless.Schema, prefix: "chlngtk"

  import Ecto.Query

  alias Passwordless.App
  alias Passwordless.Challenge
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 16

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :expires_at,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "challenge_tokens" do
    field :key, Passwordless.EncryptedBinary, redact: true
    field :key_hash, Passwordless.HashedBinary, redact: true
    field :expires_at, :utc_datetime_usec

    belongs_to :challenge, Challenge

    timestamps()
  end

  def hash(%__MODULE__{key_hash: key_hash}), do: key_hash

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
  Sign the token.
  """
  def sign_token(%__MODULE__{key: key, expires_at: expires_at}) when is_binary(key) do
    max_age = DateTime.diff(expires_at, DateTime.utc_now(), :second)
    Token.sign(Endpoint, key_salt(), key, max_age: max_age)
  end

  @doc """
  Generate an underlying key.
  """
  def generate_key do
    :crypto.strong_rand_bytes(@size)
  end

  @fields ~w(key expires_at challenge_id)a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = challenge_token, attrs \\ %{}, opts \\ []) do
    challenge_token
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_key()
    |> put_hash_fields()
    |> validate_key_hash(opts)
    |> unique_constraint(:challenge_id)
    |> unsafe_validate_unique(:challenge_id, Passwordless.Repo, prefix: Keyword.get(opts, :prefix))
    |> assoc_constraint(:challenge)
  end

  # Private

  defp validate_key(changeset) do
    validate_length(changeset, :key, is: @size, count: :bytes)
  end

  defp validate_key_hash(changeset, opts) do
    changeset
    |> validate_required(:key_hash)
    |> unique_constraint(:key_hash)
    |> unsafe_validate_unique(:key_hash, Passwordless.Repo, prefix: Keyword.get(opts, :prefix))
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
