defmodule Passwordless.DomainRecord do
  @moduledoc """
  Email domain records are used to verify domain ownership & ensure high quality sendouts.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Domain

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id, :name, :kind, :value, :verified]
  }
  @schema_prefix "public"
  schema "domain_records" do
    field :kind, Ecto.Enum, values: ~w(txt cname)a
    field :name, :string
    field :value, :string
    field :verified, :boolean, default: false

    belongs_to :domain, Domain, type: :binary_id

    timestamps()
  end

  @fields ~w(
    kind
    name
    value
    verified
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
      {:txt, _v} -> 1
      {:cname, _v} -> 2
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
    |> assoc_constraint(:domain)
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> ChangesetExt.ensure_lowercase(:name)
    |> validate_length(:name, min: 1, max: 160)
  end

  defp validate_value(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:value)
    |> validate_length(:value, min: 1, max: 160)
  end
end
