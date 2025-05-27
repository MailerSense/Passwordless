defmodule Passwordless.ActionToken do
  @moduledoc """
  A token authenticating some part of the action flow.
  """

  use Passwordless.Schema, prefix: "action_token"

  import Ecto.Query

  alias Passwordless.Action
  alias Passwordless.App
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 16
  @lifetimes [
    exchange: :timer.minutes(5),
    bearer: :timer.hours(1)
  ]
  @kinds Keyword.keys(@lifetimes)

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :kind,
      :expires_at,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "action_tokens" do
    field :kind, Ecto.Enum, values: @kinds
    field :key, Passwordless.EncryptedBinary, redact: true
    field :key_hash, Passwordless.HashedBinary, redact: true
    field :expires_at, :utc_datetime_usec

    belongs_to :action, Action

    timestamps()
  end

  @doc """
  Get expiry time for the given kind.
  """
  def get_expires_at(kind) when kind in @kinds do
    DateTime.add(DateTime.utc_now(), Keyword.fetch!(@lifetimes, kind), :millisecond)
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

  @fields ~w(kind key expires_at action_id)a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action_token, attrs \\ %{}, opts \\ []) do
    action_token
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_key()
    |> put_hash_fields()
    |> validate_key_hash(opts)
    |> unique_constraint([:action_id, :kind])
    |> unsafe_validate_unique([:action_id, :kind], Passwordless.Repo, prefix: Keyword.get(opts, :prefix))
    |> assoc_constraint(:action)
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
