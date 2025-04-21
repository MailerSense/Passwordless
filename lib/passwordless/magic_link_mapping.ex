defmodule Passwordless.MagicLinkMapping do
  @moduledoc """
  A magic link mapping.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Passwordless.App
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 16
  @primary_key false
  @timestamps_opts [type: :utc_datetime]
  @foreign_key_type Database.PrefixedUUID

  schema "magic_link_mappings" do
    field :key, Passwordless.EncryptedBinary, redact: true
    field :key_hash, Passwordless.HashedBinary, redact: true
    field :magic_link_id, :binary_id

    belongs_to :app, App

    timestamps(updated_at: false)
  end

  @doc """
  Creates a new mapping for this app.
  """
  def new(%App{} = app, attrs \\ %{}) do
    {key, key_signed} = generate_key()

    params = Map.put(attrs, :key, key)

    changeset =
      app
      |> Ecto.build_assoc(:magic_link_mappings)
      |> changeset(params)

    {key_signed, changeset}
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
  def changeset(%__MODULE__{} = message_mapping, attrs \\ %{}) do
    message_mapping
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

  def put_hash_fields(changeset) do
    Enum.reduce(@hashed_fields, changeset, fn {hashed_field, unhashed_field}, changeset ->
      if value = get_field(changeset, unhashed_field) do
        put_change(changeset, hashed_field, value)
      else
        changeset
      end
    end)
  end

  defp generate_key do
    raw = :crypto.strong_rand_bytes(@size)
    signed = Token.sign(Endpoint, key_salt(), raw)
    {raw, signed}
  end

  defp verify_key(token) when is_binary(token) do
    Token.verify(Endpoint, key_salt(), token)
  end

  defp key_salt, do: Endpoint.config(:secret_key_base)
end
