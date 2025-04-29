defmodule Passwordless.AuthToken do
  @moduledoc """
  API keys for interacting with Passwordless via JSON API.
  """

  use Passwordless.Schema, prefix: "authtkn"

  import Ecto.Query

  alias Passwordless.App
  alias Util.Base58

  @size 24
  @prefix "sk_live_"
  @permissions [
    actions: [
      :list,
      :create
    ]
  ]
  @permissions_flat Enum.flat_map(@permissions, fn {domain, actions} ->
                      [domain | Enum.map(actions, &:"#{&1}_#{domain}")]
                    end)

  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  schema "auth_tokens" do
    field :key, Passwordless.EncryptedBinary, redact: true
    field :key_hash, Passwordless.HashedBinary, redact: true
    field :permissions, {:array, Ecto.Enum}, values: @permissions_flat, default: []

    belongs_to :app, App

    timestamps()
    soft_delete_timestamp()
  end

  def permissions, do: @permissions_flat

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
      {:ok, from(a in App, join: at in assoc(a, :auth_token), where: at.key_hash == ^key, select: a)}
    end
  end

  def get_app_by_token(_), do: {:error, :invalid_key}

  @doc """
  Generate an underlying key.
  """
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
  def can?(%__MODULE__{permissions: permissions}, action) when is_atom(action) and not is_nil(action),
    do: action in permissions

  def can?(%__MODULE__{permissions: permissions}, other_actions) when is_list(other_actions),
    do: Enum.all?(other_actions, &Enum.member?(permissions, &1))

  def can?(%__MODULE__{}, _action), do: false

  @fields ~w(key permissions app_id)a
  @required_fields @fields

  @doc """
  A api key changeset.
  """
  def changeset(%__MODULE__{} = auth_token, attrs \\ %{}) do
    auth_token
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_permissions()
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
    |> validate_required(:key_hash)
    |> unique_constraint(:key_hash)
    |> unsafe_validate_unique(:key_hash, Passwordless.Repo)
  end

  defp validate_permissions(changeset) do
    changeset
    |> update_change(:permissions, &Enum.uniq/1)
    |> validate_length(:permissions, min: 1)
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
