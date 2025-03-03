defmodule Passwordless.Organizations.Membership do
  @moduledoc """
  An organization membership schema.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.Org
  alias Passwordless.Security.Roles

  @derive {
    Flop.Schema,
    sortable: [:id, :name, :email, :role, :inserted_at],
    filterable: [:id, :name, :email],
    adapter_opts: [
      join_fields: [
        name: [
          binding: :user,
          field: :name,
          ecto_type: :string
        ],
        email: [
          binding: :user,
          field: :email,
          ecto_type: :string
        ]
      ]
    ]
  }
  schema "org_memberships" do
    field :role, Ecto.Enum, values: Roles.org_roles(), default: :member

    # User
    field :name, :string, virtual: true
    field :email, :string, virtual: true

    belongs_to :org, Org, type: :binary_id
    belongs_to :user, User, type: :binary_id

    timestamps()
  end

  @doc """
  Get all memberships for an organization.
  """
  def get_by_org(query \\ __MODULE__, %Org{} = org) do
    from m in query,
      join: u in assoc(m, :user),
      as: :user,
      where: m.org_id == ^org.id,
      preload: [user: u]
  end

  @doc """
  Get a membership by user and organization.
  """
  def get_by_user_id_and_org_id(user_id, org_id) do
    from ms in __MODULE__, where: [org_id: ^org_id, user_id: ^user_id]
  end

  @doc """
  Get a membership by users and organization.
  """
  def get_by_user_ids_and_org_id(user_ids, org_id) when is_list(user_ids) do
    from ms in __MODULE__, where: ms.org_id == ^org_id and ms.user_id in ^user_ids
  end

  @doc """
  Get a membership by user and organization slug.
  """
  def get_by_user_and_org_id(%User{} = user, org_id) do
    from ms in __MODULE__, where: [org_id: ^org_id, user_id: ^user.id]
  end

  @fields ~w(
    role
    org_id
    user_id
  )a
  @required_fields @fields

  @doc """
  An organization membership changeset to update a membership.
  """
  def changeset(membership, attrs \\ %{}, _metadata \\ []) do
    membership
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:org_id, :user_id])
    |> unsafe_validate_unique([:org_id, :user_id], Passwordless.Repo)
    |> assoc_constraint(:org)
    |> assoc_constraint(:user)
  end

  @doc """
  A membership changeset to create a new membership.
  """
  def insert_changeset(%Org{} = org, %User{} = user, role \\ :member) do
    %__MODULE__{}
    |> change(%{org_id: org.id, user_id: user.id, role: role})
    |> validate_required([:org_id, :user_id, :role])
    |> unique_constraint([:org_id, :user_id])
    |> unsafe_validate_unique([:org_id, :user_id], Passwordless.Repo)
    |> assoc_constraint(:org)
    |> assoc_constraint(:user)
  end

  def is?(%__MODULE__{role: role}, role) when is_atom(role), do: true
  def is?(%__MODULE__{}, _role), do: false

  def is_or_higher?(%__MODULE__{role: role}, target_role) when is_atom(role) and is_atom(target_role) do
    roles = Enum.with_index(Roles.org_roles())
    precedences = for r <- [role, target_role], do: Enum.find(roles, fn {m, _} -> m == r end)

    case precedences do
      [{_, i}, {_, j}] when i <= j -> true
      _ -> false
    end
  end

  def is_or_higher?(%__MODULE__{}, _role), do: false

  def access_level(%__MODULE__{role: role}) when is_atom(role) do
    roles = Enum.with_index(Roles.org_roles())

    case Enum.find(roles, fn {m, _} -> m == role end) do
      {_, i} -> i
      _ -> -1
    end
  end

  def assign_user(%__MODULE__{user: %User{} = user} = membership) do
    %__MODULE__{membership | name: user.name, email: user.email}
  end

  def assign_user(%__MODULE__{} = membership), do: membership
end
