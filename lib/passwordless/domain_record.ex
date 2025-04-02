defmodule Passwordless.DomainRecord do
  @moduledoc """
  Email domain records are used to verify domain ownership & ensure high quality sendouts.
  """

  use Passwordless.Schema, prefix: "dnsrec"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Domain

  @derive {Jason.Encoder,
           only: [
             :id,
             :kind,
             :name,
             :value,
             :priority,
             :verified,
             :inserted_at,
             :updated_at
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id, :name, :kind, :value, :verified]
  }
  schema "domain_records" do
    field :kind, Ecto.Enum, values: ~w(mx txt cname)a
    field :name, :string
    field :value, :string
    field :priority, :integer, default: 0
    field :verified, :boolean, default: false

    belongs_to :domain, Domain

    timestamps()
  end

  @fields ~w(
    kind
    name
    value
    verified
    priority
    domain_id
  )a
  @required_fields @fields

  @doc """
  Get invitations for an organization.
  """
  def get_by_domain(query \\ __MODULE__, %Domain{} = domain) do
    from q in query, where: [domain_id: ^domain.id]
  end

  @doc """
  Check if an domain record is verified.
  """
  def is_verified?(%__MODULE__{verified: verified}), do: verified

  @doc """
  Check if an identity record is a DMARC record.
  """
  def is_dmarc?(%__MODULE__{kind: :txt, value: value}), do: String.starts_with?(value, "v=DMARC1")
  def is_dmarc?(%__MODULE__{}), do: false

  @doc """
  Get the DNS domain name for an domain record.
  """
  def domain_name(%Domain{name: domain}, %__MODULE__{name: record}) when is_binary(record) and is_binary(domain) do
    {:ok, %{domain: root_domain, tld: tld}} = Domainatrex.parse(domain)
    "#{record}.#{root_domain}.#{tld}"
  end

  def domain_name(%Domain{}, %__MODULE__{}), do: nil

  @doc """
  Order domain records by kind and priority.
  """
  def order(records) do
    records
    |> Enum.group_by(& &1.kind)
    |> Enum.sort_by(fn
      {:mx, _v} -> 1
      {:txt, _v} -> 2
      {:cname, _v} -> 3
    end)
    |> Enum.map(&elem(&1, 1))
    |> Enum.flat_map(&Enum.sort_by(&1, fn r -> r.id end))
  end

  @doc """
  An email domain record changeset.
  """
  def changeset(%__MODULE__{} = domain_record, attrs \\ %{}) do
    domain_record
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_value()
    |> unique_constraint([:domain_id, :kind, :name, :value])
    |> unsafe_validate_unique([:domain_id, :kind, :name, :value], Passwordless.Repo)
    |> assoc_constraint(:domain)
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> ChangesetExt.ensure_lowercase(:name)
    |> validate_length(:name, min: 1, max: 255)
  end

  defp validate_value(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:value)
    |> validate_length(:value, min: 1, max: 255)
  end
end
