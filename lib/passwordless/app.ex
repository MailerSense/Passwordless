defmodule Passwordless.App do
  @moduledoc """
  An app contains passwordless resources.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Actor
  alias Passwordless.Organizations.Org
  alias Passwordless.Repo

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  @derive {Phoenix.Param, key: :slug}
  schema "apps" do
    field :slug, :string
    field :name, :string
    field :description, :string

    has_many :actors, Actor

    belongs_to :org, Org, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Get by organization.
  """
  def get_by_org(%Org{} = org) do
    from c in __MODULE__, where: c.org_id == ^org.id
  end

  @fields ~w(name description org_id)a
  @required_fields ~w(name org_id)a

  @doc """
  A changeset to create a new organization.
  """
  def insert_changeset(org, attrs \\ %{}, _metadata \\ []) do
    org
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_description()
    |> name_to_slug()
    |> validate_slug()
    |> assoc_constraint(:org)
  end

  @doc """
  A changeset to update an existing organization.
  """
  def changeset(org, attrs \\ %{}, _metadata \\ []) do
    org
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_description()
    |> assoc_constraint(:org)
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 160)
  end

  defp validate_description(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:description)
    |> validate_length(:description, min: 1, max: 1024)
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_required(:slug)
    |> unique_constraint(:slug)
    |> unsafe_validate_unique(:slug, Passwordless.Repo)
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
