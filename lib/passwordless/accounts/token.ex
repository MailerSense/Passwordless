defmodule Passwordless.Accounts.Token do
  @moduledoc """
  A key is assigned to a user for a specific context (purpose).
  """

  use Passwordless.Schema, prefix: "acctkn"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Accounts.User
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 16
  @lifetimes [
    session: :timer.hours(24) * 7,
    email_change: :timer.hours(6),
    email_confirmation: :timer.hours(6),
    password_reset: :timer.hours(6),
    passwordless_sign_in: :timer.minutes(30)
  ]
  @contexts Keyword.keys(@lifetimes)

  schema "user_tokens" do
    field :key, Passwordless.EncryptedBinary, redact: true
    field :key_hash, Passwordless.HashedBinary, redact: true
    field :context, Ecto.Enum, values: @contexts
    field :email, :string

    belongs_to :user, User

    timestamps()
  end

  def contexts, do: @contexts

  @doc """
  Creates a new key for the given user and context.
  """
  def new(%User{} = user, context, attrs \\ %{}) when context in @contexts do
    {key, key_signed} = generate_key(context)

    params = Map.merge(attrs, %{key: key, context: context})

    changeset =
      user
      |> Ecto.build_assoc(:tokens)
      |> changeset(params)

    {key_signed, changeset}
  end

  def hash(%__MODULE__{key_hash: key_hash}), do: key_hash

  @fields ~w(key email context user_id)a
  @required_fields @fields -- [:email]

  @doc """
  A user key changeset.
  """
  def changeset(%__MODULE__{} = key, attrs \\ %{}) do
    key
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_key()
    |> put_hash_fields()
    |> validate_key_hash()
    |> validate_email()
    |> assoc_constraint(:user)
  end

  @edit_fields ~w(email context user_id)a
  @edit_required_fields @edit_fields

  @doc """
  An edit user key changeset.
  """
  def edit_changeset(key, attrs \\ %{}, _metadata) do
    key
    |> cast(attrs, @edit_fields)
    |> validate_required(@edit_required_fields)
    |> validate_email()
    |> assoc_constraint(:user)
  end

  @doc """
  Query for getting user by key and context.
  """
  def get_user_by_token_and_context(key_signed, context) when is_binary(key_signed) and context in @contexts do
    with {:ok, key} <- verify_key(key_signed, context) do
      {:ok,
       from(t in __MODULE__,
         where:
           t.context == ^context and
             t.key_hash == ^key and
             t.inserted_at > ago(^Keyword.fetch!(@lifetimes, context), "millisecond"),
         join: u in assoc(t, :user),
         select: u
       )}
    end
  end

  @doc """
  Query for getting key by user and key and context.
  """
  def get_by_user_and_token_and_context(%User{id: user_id}, key_signed, context)
      when is_binary(key_signed) and context in @contexts do
    with {:ok, key} <- verify_key(key_signed, context) do
      {:ok,
       from(t in __MODULE__,
         where:
           t.user_id == ^user_id and
             t.key_hash == ^key and
             t.context == ^context and
             t.inserted_at > ago(^Keyword.fetch!(@lifetimes, context), "millisecond")
       )}
    end
  end

  @doc """
  Query for getting key by key and context.
  """
  def get_by_token_and_context(key_signed, context) when is_binary(key_signed) and context in @contexts do
    with {:ok, key} <- verify_key(key_signed, context) do
      {:ok, from(t in __MODULE__, where: t.key_hash == ^key and t.context == ^context)}
    end
  end

  def get_tokens_by_user_and_context(%User{id: user_id}, context) when context in @contexts do
    from(t in __MODULE__,
      where:
        t.user_id == ^user_id and
          t.context == ^context and
          t.inserted_at > ago(^Keyword.fetch!(@lifetimes, context), "millisecond")
    )
  end

  # Private

  defp validate_key(changeset) do
    validate_length(changeset, :key, is: @size, count: :bytes)
  end

  defp validate_key_hash(changeset) do
    changeset
    |> unique_constraint(:key_hash)
    |> unsafe_validate_unique(:key_hash, Passwordless.Repo)
  end

  defp validate_email(changeset) do
    ChangesetExt.validate_email(changeset, :email)
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

  defp generate_key(context) when context in @contexts do
    raw = :crypto.strong_rand_bytes(@size)
    signed = Token.sign(Endpoint, key_salt(), raw)
    {raw, signed}
  end

  defp verify_key(key, context) when is_binary(key) and context in @contexts do
    Token.verify(Endpoint, key_salt(), key, max_age: div(Keyword.fetch!(@lifetimes, context), 1000))
  end

  defp key_salt, do: Endpoint.config(:secret_key_base)
end
