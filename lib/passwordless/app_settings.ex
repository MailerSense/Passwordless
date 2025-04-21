defmodule Passwordless.AppSettings do
  @moduledoc """
  An app contains passwordless resources.
  """

  use Passwordless.Schema, prefix: "appstg"

  alias Database.ChangesetExt
  alias Passwordless.App

  @actions ~w(allow block)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :logo,
      :website,
      :display_name,
      :primary_button_color,
      :secondary_button_color,
      :email_configuration_set,
      :email_tracking,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "app_settings" do
    field :logo, :string
    field :website, :string
    field :display_name, :string
    field :primary_button_color, :string, default: "#1570ef"
    field :secondary_button_color, :string, default: "#ffffff"
    field :email_configuration_set, :string
    field :email_tracking, :boolean, default: false
    field :default_action, Ecto.Enum, values: @actions, default: :block
    field :whitelist_ip_access, :boolean, default: false

    embeds_many :whitelisted_ip_addresses, IPAddress, on_replace: :delete do
      @derive Jason.Encoder

      field :address, :string
    end

    belongs_to :app, App

    timestamps()
  end

  def actions, do: @actions

  @fields ~w(
    logo
    website
    display_name
    primary_button_color
    secondary_button_color
    email_configuration_set
    email_tracking
    default_action
    whitelist_ip_access
    app_id
  )a
  @required_fields @fields -- [:logo, :email_configuration_set, :app_id]

  @doc """
  A changeset to update an existing organization.
  """
  def changeset(org, attrs \\ %{}, _metadata \\ []) do
    org
    |> cast(attrs, @fields)
    |> cast_embed(:whitelisted_ip_addresses,
      with: &whitelisted_ip_changeset/2,
      sort_param: :whitelisted_ip_addresses_sort,
      drop_param: :whitelisted_ip_addresses_drop
    )
    |> validate_required(@required_fields)
    |> validate_string(:display_name)
    |> validate_hex_color(:primary_button_color)
    |> validate_hex_color(:secondary_button_color)
    |> validate_website()
    |> unique_constraint(:app_id)
    |> assoc_constraint(:app)
  end

  # Private

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> ChangesetExt.validate_profanities(field)
    |> validate_length(field, min: 1, max: 64)
  end

  defp validate_hex_color(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> validate_length(field, is: 7)
    |> validate_format(field, ~r/^#[0-9a-fA-F]{6}$/, message: "must be a hex color")
  end

  defp validate_website(changeset) do
    ChangesetExt.validate_url(changeset, :website)
  end

  defp whitelisted_ip_changeset(%__MODULE__.IPAddress{} = ip_address, attrs) do
    ip_address
    |> cast(attrs, [:address])
    |> validate_required([:address])
    |> ChangesetExt.validate_cidr(:address)
  end
end
