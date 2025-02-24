defmodule Passwordless.Organizations.Org do
  @moduledoc """
  An organization is a group of users that can collaborate on resources.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Accounts.User
  alias Passwordless.Activity.Log
  alias Passwordless.App
  alias Passwordless.Organizations.AuthToken
  alias Passwordless.Organizations.Invitation
  alias Passwordless.Organizations.Membership
  alias Passwordless.Repo

  @tags ~w(admin)a

  @derive {
    Flop.Schema,
    filterable: [], sortable: [:id]
  }
  @derive {Phoenix.Param, key: :slug}
  schema "orgs" do
    field :slug, :string
    field :name, :string
    field :email, :string
    field :tags, {:array, Ecto.Enum}, values: @tags, default: []

    field :full_name, :string, virtual: true

    has_one :billing_customer, Billing.Customer

    has_many :apps, App
    has_many :logs, Log
    has_many :auth_tokens, AuthToken
    has_many :memberships, Membership
    has_many :invitations, Invitation

    many_to_many :users, User, join_through: Membership, unique: true

    timestamps()
    soft_delete_timestamp()
  end

  def is_admin?(%__MODULE__{tags: tags}) do
    Enum.member?(tags, :admin)
  end

  @fields ~w(
    name
    email
    tags
  )a
  @required_fields @fields

  @doc """
  A changeset to create a new organization.
  """
  def insert_changeset(org, attrs \\ %{}, _metadata \\ []) do
    org
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_email()
    |> validate_tags()
    |> name_to_slug()
    |> validate_slug()
  end

  @doc """
  A changeset to update an existing organization.
  """
  def update_changeset(org, attrs \\ %{}, _metadata \\ []) do
    org
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_email()
    |> validate_tags()
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 160)
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_required(:slug)
    |> unique_constraint(:slug)
    |> unsafe_validate_unique(:slug, Passwordless.Repo)
  end

  defp validate_email(changeset) do
    ChangesetExt.validate_email(changeset)
  end

  defp validate_tags(changeset) do
    update_change(changeset, :tags, &Enum.uniq/1)
  end

  defp name_to_slug(changeset) do
    case get_change(changeset, :name) do
      name when is_binary(name) ->
        slug = Slug.slugify(name)

        slug =
          Util.generate_until(
            slug,
            fn _prev -> slug <> "-" <> Util.random_numeric_string(3) end,
            fn slug -> Repo.exists?(from __MODULE__, where: [slug: ^slug]) end
          )

        put_change(changeset, :slug, slug)

      _ ->
        changeset
    end
  end
end
