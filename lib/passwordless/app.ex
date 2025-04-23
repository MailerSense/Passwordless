defmodule Passwordless.App do
  @moduledoc """
  An app contains passwordless resources.
  """

  use Passwordless.Schema, prefix: "app"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.AppSettings
  alias Passwordless.Authenticators
  alias Passwordless.AuthToken
  alias Passwordless.Domain
  alias Passwordless.EmailMessageMapping
  alias Passwordless.EmailTemplate
  alias Passwordless.EmailUnsubscribeLinkMapping
  alias Passwordless.MagicLinkMapping
  alias Passwordless.Media
  alias Passwordless.Organizations.Org

  @states ~w(active)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :name,
      :state,
      :settings,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "apps" do
    field :name, :string
    field :state, Ecto.Enum, values: @states, default: :active

    has_one :settings, AppSettings, on_replace: :update
    has_one :email_domain, Domain, where: [purpose: :email]
    has_one :tracking_domain, Domain, where: [purpose: :tracking]
    has_one :auth_token, AuthToken

    has_one :email_otp, Authenticators.EmailOTP
    has_one :magic_link, Authenticators.MagicLink
    has_one :passkey, Authenticators.Passkey
    has_one :security_key, Authenticators.SecurityKey
    has_one :totp, Authenticators.TOTP
    has_one :recovery_codes, Authenticators.RecoveryCodes

    has_many :media, Media, preload_order: [asc: :inserted_at]
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
    state
    org_id
  )a
  @required_fields @fields

  @doc """
  A changeset to update an existing organization.
  """
  def changeset(org, attrs \\ %{}, _metadata \\ []) do
    org
    |> cast(attrs, @fields)
    |> cast_assoc(:settings)
    |> validate_required(@required_fields)
    |> validate_string(:name)
    |> assoc_constraint(:org)
  end

  # Private

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> ChangesetExt.validate_profanities(field)
    |> validate_length(field, min: 1, max: 64)
  end
end
