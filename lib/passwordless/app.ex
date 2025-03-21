defmodule Passwordless.App do
  @moduledoc """
  An app contains passwordless resources.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Authenticators
  alias Passwordless.AuthToken
  alias Passwordless.Domain
  alias Passwordless.EmailMessageMapping
  alias Passwordless.EmailTemplate
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
    has_one :auth_token, AuthToken

    has_one :email, Authenticators.Email
    has_one :sms, Authenticators.SMS
    has_one :whatsapp, Authenticators.WhatsApp
    has_one :magic_link, Authenticators.MagicLink
    has_one :totp, Authenticators.TOTP
    has_one :security_key, Authenticators.SecurityKey
    has_one :passkey, Authenticators.Passkey
    has_one :recovery_codes, Authenticators.RecoveryCodes

    has_many :email_templates, EmailTemplate
    has_many :email_message_mappings, EmailMessageMapping

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
