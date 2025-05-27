defmodule Passwordless.Organizations.OrgSettings do
  @moduledoc """
  An org contains passwordless resources.
  """

  use Passwordless.Schema, prefix: "org_settings"

  alias Money.Ecto.Amount.Type, as: Cost

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :usage_limit_enabled,
      :usage_limit,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "org_settings" do
    field :usage_limit_enabled, :boolean, default: false
    field :usage_limit, Cost

    belongs_to :org, Passwordless.Organizations.Org

    timestamps()
  end

  @fields ~w(
    usage_limit_enabled
    usage_limit
    org_id
  )a
  @required_fields ~w(
    usage_limit_enabled
    usage_limit
  )a

  @doc """
  A changeset to update an existing organization.
  """
  def changeset(org, attrs \\ %{}) do
    org
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:org_id)
    |> assoc_constraint(:org)
  end
end
