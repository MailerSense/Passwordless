defmodule Passwordless.App do
  @moduledoc """
  An app contains passwordless resources.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Actor
  alias Passwordless.Domain
  alias Passwordless.Email
  alias Passwordless.Methods
  alias Passwordless.Organizations.Org
  alias Passwordless.Phone

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "apps" do
    field :name, :string
    field :website, :string
    field :description, :string

    # Domain
    has_one :domain, Domain

    # Methods
    has_one :magic_link, Methods.MagicLink
    has_one :email, Methods.Email
    has_one :sms, Methods.SMS
    has_one :authenticator, Methods.Authenticator
    has_one :security_key, Methods.SecurityKey
    has_one :passkey, Methods.Passkey

    # Entities
    has_many :actors, Actor
    has_many :emails, Email
    has_many :phones, Phone

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

  @fields ~w(name website description org_id)a
  @required_fields ~w(name website org_id)a

  @doc """
  A changeset to update an existing organization.
  """
  def changeset(org, attrs \\ %{}, _metadata \\ []) do
    org
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_website()
    |> validate_description()
    |> assoc_constraint(:org)
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 128)
  end

  defp validate_website(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:website)
    |> validate_length(:name, min: 1, max: 1024)
  end

  defp validate_description(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:description)
    |> validate_length(:description, min: 1, max: 1024)
  end
end
