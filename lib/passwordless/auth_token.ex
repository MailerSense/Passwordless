defmodule Passwordless.AuthToken do
  @moduledoc """
  API keys for interacting with Passwordless via JSON API.
  """

  use Passwordless.Schema, prefix: "authtkn"

  import Ecto.Query

  alias Passwordless.App
  alias Passwordless.Security.Roles
  alias Util.Base58

  @size 32
  @prefix "sk_live_"

  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  schema "auth_tokens" do
    field :key, Passwordless.EncryptedBinary, redact: true
    field :key_hash, Passwordless.HashedBinary, redact: true
    field :scopes, {:array, Ecto.Enum}, values: Roles.auth_token_scopes(), default: []

    belongs_to :app, App

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Get invitations for an app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, where: [app_id: ^app.id]
  end

  @doc """
  Get revoked api keys.
  """
  def get_revoked(query \\ __MODULE__) do
    from q in query, where: q.state == :revoked
  end

  @doc """
  Get the app and key for an api key.
  """
  def get_app_and_key(@prefix <> auth_token) when is_binary(auth_token) do
    with {:ok, key} <- Base58.decode58(auth_token) do
      {:ok,
       from(a in App,
         join: at in assoc(a, :auth_token),
         where: at.key_hash == ^key,
         select: {struct(a, [:id]), at}
       )}
    end
  end

  def get_app_and_key(_), do: {:error, :invalid_key}

  @doc """
  Get the app and key for an api key.
  """
  def get_app_by_token(@prefix <> auth_token) when is_binary(auth_token) do
    with {:ok, key} <- Base58.decode58(auth_token) do
      {:ok, from(a in App, join: at in assoc(a, :auth_token), where: at.key_hash == ^key, select: [:id])}
    end
  end

  def get_app_by_token(_), do: {:error, :invalid_key}

  def generate_key do
    :crypto.strong_rand_bytes(@size)
  end

  @doc """
  Get the human readable key.
  """
  def preview(%__MODULE__{}) do
    "#{@prefix}#{Enum.join(List.duplicate("*", div(@size, 2)))}"
  end

  @doc """
  Get the human readable key.
  """
  def encode(%__MODULE__{key: key}) do
    "#{@prefix}#{Base58.encode58(key)}"
  end

  @doc """
  Can the api key perform the given scope?
  """
  def can?(%__MODULE__{scopes: scopes}, scope) when is_atom(scope) and not is_nil(scope), do: scope in scopes

  def can?(%__MODULE__{scopes: scopes}, other_scopes) when is_list(other_scopes),
    do: Enum.all?(other_scopes, &Enum.member?(scopes, &1))

  def can?(%__MODULE__{}, _scope), do: false

  @fields ~w(key scopes app_id)a
  @required_fields @fields

  @doc """
  A api key changeset.
  """
  def changeset(%__MODULE__{} = auth_token, attrs \\ %{}) do
    auth_token
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_scopes()
    |> validate_key()
    |> put_hash_fields()
    |> validate_key_hash()
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
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

  defp validate_scopes(changeset) do
    changeset
    |> update_change(:scopes, &Enum.uniq/1)
    |> validate_length(:scopes, min: 1)
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
end
