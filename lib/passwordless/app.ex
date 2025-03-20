defmodule Passwordless.App do
  @moduledoc """
  An app contains passwordless resources.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Domain
  alias Passwordless.EmailTemplate
  alias Passwordless.Methods
  alias Passwordless.Organizations.Org

  @states ~w(active)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "apps" do
    field :name, :string
    field :logo, :string
    field :state, Ecto.Enum, values: @states, default: :active
    field :website, :string
    field :display_name, :string
    field :primary_button_color, :string, default: "#1570EF"
    field :secondary_button_color, :string, default: "#FFFFFF"

    has_one :domain, Domain

    has_one :email, Methods.Email
    has_one :sms, Methods.SMS
    has_one :whatsapp, Methods.WhatsApp
    has_one :magic_link, Methods.MagicLink
    has_one :authenticator, Methods.Authenticator
    has_one :security_key, Methods.SecurityKey
    has_one :passkey, Methods.Passkey
    has_one :recovery_codes, Methods.RecoveryCodes

    has_many :email_templates, EmailTemplate

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
    logo
    state
    website
    display_name
    primary_button_color
    secondary_button_color
    org_id
  )a
  @required_fields @fields -- [:logo]

  @doc """
  A changeset to update an existing organization.
  """
  def changeset(org, attrs \\ %{}, _metadata \\ []) do
    org
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_string(:name)
    |> validate_string(:display_name)
    |> validate_website()
    |> assoc_constraint(:org)
  end

  # Private

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> validate_length(field, min: 1, max: 255)
  end

  defp validate_website(changeset) do
    ChangesetExt.validate_url(changeset, :website)
  end
end
