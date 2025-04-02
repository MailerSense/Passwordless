defmodule Passwordless.AuthToken do
  @moduledoc """
  API keys for interacting with Passwordless via JSON API.
  """

  use Passwordless.Schema, prefix: "authtkn"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.App
  alias Passwordless.Security.Roles
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 12
  @states ~w(active revoked)a

  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  schema "auth_tokens" do
    field :key, :binary, redact: true
    field :name, :string
    field :state, Ecto.Enum, values: @states, default: :active
    field :scopes, {:array, Ecto.Enum}, values: Roles.auth_token_scopes(), default: []

    belongs_to :app, App

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Creates a new API key for the given app.
  """
  def new(%App{} = app, attrs \\ %{}) do
    {key, key_signed} = generate_key()

    params = Map.put(attrs, "key", key)

    changeset =
      app
      |> Ecto.build_assoc(:auth_token)
      |> changeset(params)

    {key_signed, changeset}
  end

  def sign(%__MODULE__{key: key}) do
    Token.sign(Endpoint, key_salt(), key)
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
  def get_app_and_key(auth_token) when is_binary(auth_token) do
    with {:ok, key} <- verify_key(auth_token) do
      {:ok,
       from(a in App,
         join: at in assoc(a, :auth_tokens),
         where: at.key == ^key,
         select: {a, at}
       )}
    end
  end

  @doc """
  Can the api key perform the given scope?
  """
  def can?(%__MODULE__{scopes: scopes}, scope) when is_atom(scope) and not is_nil(scope), do: scope in scopes

  def can?(%__MODULE__{scopes: scopes}, other_scopes) when is_list(other_scopes),
    do: Enum.all?(other_scopes, &Enum.member?(scopes, &1))

  def can?(%__MODULE__{}, _scope), do: false

  @fields ~w(key name state scopes app_id)a
  @required_fields @fields

  @doc """
  A api key changeset.
  """
  def changeset(%__MODULE__{} = auth_token, attrs \\ %{}) do
    auth_token
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_scopes()
    |> validate_name()
    |> validate_key()
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end

  @create_fields ~w(name scopes app_id)a
  @create_required_fields @create_fields

  @doc """
  A api key changeset.
  """
  def create_changeset(%__MODULE__{} = auth_token, attrs \\ %{}) do
    auth_token
    |> cast(attrs, @create_fields)
    |> validate_required(@create_required_fields)
    |> validate_scopes()
    |> validate_name()
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end

  # Private

  defp validate_key(changeset) do
    changeset
    |> validate_length(:key, is: @size, count: :bytes)
    |> unique_constraint(:key)
    |> unsafe_validate_unique(:key, Passwordless.Repo)
  end

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 255)
  end

  defp validate_scopes(changeset) do
    changeset
    |> update_change(:scopes, &Enum.uniq/1)
    |> validate_length(:scopes, min: 1)
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
