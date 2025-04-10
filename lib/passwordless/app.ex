defmodule Passwordless.App do
  @moduledoc """
  An app contains passwordless resources.
  """

  use Passwordless.Schema, prefix: "app"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Authenticators
  alias Passwordless.AuthToken
  alias Passwordless.Domain
  alias Passwordless.EmailMessageMapping
  alias Passwordless.EmailTemplate
  alias Passwordless.EmailUnsubscribeLinkMapping
  alias Passwordless.MagicLinkMapping
  alias Passwordless.Organizations.Org

  @states ~w(active)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :name,
      :logo,
      :state,
      :website,
      :display_name,
      :primary_button_color,
      :secondary_button_color,
      :email_configuration_set,
      :email_tracking,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]
  }
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
    field :email_configuration_set, :string
    field :email_tracking, :boolean, default: false

    has_one :email_domain, Domain, where: [purpose: :email]
    has_one :tracking_domain, Domain, where: [purpose: :tracking]
    has_one :auth_token, AuthToken

    has_one :email, Authenticators.Email
    has_one :sms, Authenticators.SMS
    has_one :whatsapp, Authenticators.WhatsApp
    has_one :magic_link, Authenticators.MagicLink
    has_one :totp, Authenticators.TOTP
    has_one :security_key, Authenticators.SecurityKey
    has_one :passkey, Authenticators.Passkey
    has_one :recovery_codes, Authenticators.RecoveryCodes

    has_many :domains, Domain, preload_order: [asc: :inserted_at]
    has_many :email_templates, EmailTemplate, preload_order: [asc: :inserted_at]
    has_many :email_message_mappings, EmailMessageMapping, preload_order: [asc: :inserted_at]
    has_many :magic_link_mappings, MagicLinkMapping, preload_order: [asc: :inserted_at]

    has_many :email_unsubscribe_link_mappings, EmailUnsubscribeLinkMapping, preload_order: [asc: :inserted_at]

    belongs_to :org, Org

    timestamps()
    soft_delete_timestamp()
  end

  def states, do: @states

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
    email_configuration_set
    email_tracking
    org_id
  )a
  @required_fields @fields -- [:logo, :email_configuration_set]

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
