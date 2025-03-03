defmodule Passwordless.App do
  @moduledoc """
  An app contains passwordless resources.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Domain
  alias Passwordless.Methods
  alias Passwordless.Organizations.Org

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "apps" do
    field :name, :string
    field :website, :string
    field :display_name, :string
    field :primary_button_color, :string, default: "#1570EF"
    field :secondary_button_color, :string, default: "#FFFFFF"

    # Domain
    has_one :domain, Domain

    # Methods
    has_one :magic_link, Methods.MagicLink
    has_one :email, Methods.Email
    has_one :sms, Methods.SMS
    has_one :authenticator, Methods.Authenticator
    has_one :security_key, Methods.SecurityKey
    has_one :passkey, Methods.Passkey

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

  @fields ~w(
    name
    website
    display_name
    primary_button_color
    secondary_button_color
    org_id
  )a
  @required_fields @fields

  @doc """
  A changeset to update an existing organization.
  """
  def changeset(org, attrs \\ %{}, _metadata \\ []) do
    org
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_website()
    |> validate_display_name()
    |> assoc_constraint(:org)
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 128)
  end

  defp validate_website(changeset) do
    ChangesetExt.validate_url(changeset, :website)
  end

  defp validate_display_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:display_name)
    |> validate_length(:display_name, min: 1, max: 128)
  end
end
