defmodule Passwordless.Phone do
  @moduledoc """
  A phone.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Actor

  @channels ~w(sms whatsapp)a

  @derive {Jason.Encoder,
           only: [
             :id,
             :number,
             :region,
             :canonical,
             :primary,
             :verified
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "phones" do
    field :number, :string
    field :region, :string
    field :canonical, :string
    field :primary, :boolean, default: false
    field :verified, :boolean, default: false
    field :channels, {:array, Ecto.Enum}, values: @channels, default: [:sms]

    belongs_to :actor, Actor, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  def format(%__MODULE__{canonical: canonical}) when is_binary(canonical) do
    case ExPhoneNumber.parse(canonical, "") do
      {:ok, number} -> ExPhoneNumber.format(number, :international)
      _ -> canonical
    end
  end

  def format(%__MODULE__{region: region, number: number}) when is_binary(region) and is_binary(number) do
    with {:ok, phone_number} <- ExPhoneNumber.parse(number, region),
         true <- ExPhoneNumber.is_possible_number?(phone_number) do
      ExPhoneNumber.format(phone_number, :international)
    else
      _ -> nil
    end
  end

  @fields ~w(
    number
    region
    canonical
    primary
    verified
    channels
    actor_id
  )a
  @required_fields @fields

  @doc """
  A regional changeset.
  """
  def regional_changeset(%__MODULE__{} = actor_email, attrs \\ %{}, opts \\ []) do
    excluded = [:canonical]

    actor_email
    |> cast(attrs, @fields -- excluded)
    |> validate_required(@required_fields -- excluded)
    |> validate_regional_phone_number()
    |> base_changeset(opts)
  end

  @doc """
  A canonical changeset.
  """
  def canonical_changeset(%__MODULE__{} = actor_email, attrs \\ %{}, opts \\ []) do
    excluded = [:number, :region]

    actor_email
    |> cast(attrs, @fields -- excluded)
    |> validate_required(@required_fields -- excluded)
    |> validate_canonical_phone_number()
    |> base_changeset(opts)
  end

  # Private

  defp validate_regional_phone_number(%Ecto.Changeset{valid?: true} = changeset) do
    changeset =
      changeset
      |> ChangesetExt.ensure_trimmed(:number)
      |> ChangesetExt.ensure_trimmed(:region)

    number = fetch_field!(changeset, :number)
    region = fetch_field!(changeset, :region)

    with {:ok, phone_number} <- ExPhoneNumber.parse(number, region),
         true <- ExPhoneNumber.is_possible_number?(phone_number) do
      put_change(changeset, :canonical, ExPhoneNumber.format(phone_number, :e164))
    else
      {:error, message} -> add_error(changeset, :number, message)
      _ -> add_error(changeset, :number, "is invalid")
    end
  end

  defp validate_regional_phone_number(changeset), do: changeset

  defp validate_canonical_phone_number(%Ecto.Changeset{valid?: true} = changeset) do
    changeset = ChangesetExt.ensure_trimmed(changeset, :canonical)
    canonical = fetch_field!(changeset, :canonical)

    with {:ok, phone_number} <- ExPhoneNumber.parse(canonical, ""),
         true <- ExPhoneNumber.is_possible_number?(phone_number) do
      changeset
      |> put_change(:number, to_string(phone_number.national_number))
      |> put_change(:region, ExPhoneNumber.Metadata.get_region_code_for_country_code(phone_number.country_code))
    else
      {:error, message} -> add_error(changeset, :canonical, message)
      _ -> add_error(changeset, :canonical, "is invalid")
    end
  end

  defp validate_canonical_phone_number(changeset), do: changeset

  defp base_changeset(changeset, opts \\ []) do
    changeset
    |> validate_channels()
    |> unique_constraint([:actor_id, :primary], error_key: :primary)
    |> unique_constraint([:actor_id, :canonical], error_key: :canonical)
    |> unsafe_validate_unique([:actor_id, :primary], Passwordless.Repo,
      prefix: Keyword.get(opts, :prefix),
      query: from(p in __MODULE__, where: p.primary == true),
      error_key: :primary
    )
    |> unsafe_validate_unique([:actor_id, :canonical], Passwordless.Repo,
      prefix: Keyword.get(opts, :prefix),
      error_key: :canonical
    )
    |> assoc_constraint(:actor)
  end

  defp validate_channels(changeset) do
    ChangesetExt.clean_array(changeset, :channels)
  end
end
