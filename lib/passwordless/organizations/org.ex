defmodule Passwordless.Organizations.Org do
  @moduledoc """
  An organization is a group of users that can collaborate on resources.
  """

  use Passwordless.Schema, prefix: "org"

  alias Database.ChangesetExt
  alias Passwordless.Accounts.User
  alias Passwordless.Activity.Log
  alias Passwordless.App
  alias Passwordless.BillingCustomer
  alias Passwordless.BillingItem
  alias Passwordless.Organizations.Invitation
  alias Passwordless.Organizations.Membership

  @tags ~w(admin system default)a
  @states ~w(active)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "orgs" do
    field :name, :string
    field :email, :string
    field :state, Ecto.Enum, values: @states, default: :active
    field :tags, {:array, Ecto.Enum}, values: @tags, default: []

    field :full_name, :string, virtual: true

    has_one :billing_customer, BillingCustomer

    has_many :apps, App, preload_order: [asc: :inserted_at]
    has_many :logs, Log, preload_order: [asc: :inserted_at]
    has_many :memberships, Membership, preload_order: [asc: :inserted_at]
    has_many :invitations, Invitation, preload_order: [asc: :inserted_at]
    has_many :billing_items, BillingItem, preload_order: [asc: :inserted_at]

    many_to_many :users, User, join_through: Membership, unique: true

    timestamps()
    soft_delete_timestamp()
  end

  def admin?(%__MODULE__{tags: tags}) do
    Enum.member?(tags, :admin)
  end

  @fields ~w(
    name
    email
    state
    tags
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(org, attrs \\ %{}, _opts \\ []) do
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
    |> validate_length(:name, min: 1, max: 255)
  end

  defp validate_email(changeset) do
    ChangesetExt.validate_email(changeset)
  end

  defp validate_tags(changeset) do
    ChangesetExt.clean_array(changeset, :tags)
  end
end
