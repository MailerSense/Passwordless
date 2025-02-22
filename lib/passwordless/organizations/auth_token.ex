defmodule Passwordless.Organizations.AuthToken do
  @moduledoc """
  API keys for interacting with Passwordless via JSON API.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Organizations.Org
  alias Passwordless.Security.Roles
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 16
  @states ~w(active revoked)a
  @derive {
    Flop.Schema,
    sortable: [:id, :name, :scopes, :state, :inserted_at], filterable: [:id]
  }
  schema "auth_tokens" do
    field :key, :binary
    field :name, :string
    field :state, Ecto.Enum, values: @states, default: :active
    field :scopes, {:array, Ecto.Enum}, values: Roles.auth_token_scopes()
    field :signature, :string

    belongs_to :org, Org, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Creates a new API key for the given org.
  """
  def new(%Org{} = org, attrs \\ %{}) do
    {key, key_signed} = generate_key()

    params =
      attrs
      |> Map.put("key", key)
      |> Map.put("signature", generate_signature(key_signed))
      |> Map.put_new("scopes", [])

    changeset =
      org
      |> Ecto.build_assoc(:auth_tokens)
      |> changeset(params)

    {key_signed, changeset}
  end

  @doc """
  Get invitations for an organization.
  """
  def get_by_org(query \\ __MODULE__, %Org{} = org) do
    from q in query, where: [org_id: ^org.id]
  end

  @doc """
  Get revoked api keys.
  """
  def get_revoked(query \\ __MODULE__) do
    from q in query, where: q.state == :revoked
  end

  @doc """
  Get the organization and key for an api key.
  """
  def get_org_and_key(auth_token) when is_binary(auth_token) do
    with {:ok, key} <- verify_key(auth_token) do
      {:ok,
       from(o in Org,
         join: a in assoc(o, :auth_tokens),
         where: a.key == ^key,
         select: {o, a}
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

  @fields ~w(signature key name state scopes org_id)a
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
    |> assoc_constraint(:org)
  end

  @create_fields ~w(name scopes org_id)a
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
    |> assoc_constraint(:org)
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
    |> validate_length(:name, min: 1, max: 160)
  end

  defp validate_scopes(changeset) do
    changeset
    |> update_change(:scopes, &Enum.uniq/1)
    |> validate_length(:scopes, min: 1)
  end

  defp generate_signature(signed_token) when is_binary(signed_token) do
    case String.split(signed_token, ".", parts: 3) do
      [_kind, payload, _signature] -> Util.slice_central(payload, @size)
      _ -> nil
    end
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
