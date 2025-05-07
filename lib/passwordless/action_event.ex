defmodule Passwordless.ActionEvent do
  @moduledoc """
  An action avent.
  """

  use Passwordless.Schema, prefix: "event"

  alias Database.ChangesetExt
  alias Database.Inet
  alias Passwordless.Action

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :event,
      :metadata,
      :inserted_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "action_events" do
    field :event, :string

    embeds_one :metadata, Metadata, on_replace: :delete do
      @derive Jason.Encoder

      field :before, :map, default: %{}
      field :after, :map, default: %{}
      field :attrs, :map, default: %{}
    end

    field :user_agent, :string
    field :ip_address, Inet
    field :country, :string
    field :city, :string

    belongs_to :action, Action

    timestamps(updated_at: false)
  end

  @fields ~w(
    event
    user_agent
    ip_address
    country
    city
    action_id
  )a
  @required_fields ~w(
    event
    action_id
  )a

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action_event, attrs \\ %{}) do
    action_event
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_ip_address()
    |> validate_user_agent()
    |> validate_string(:country)
    |> validate_string(:city)
    |> assoc_constraint(:action)
    |> cast_embed(:metadata, with: &metadata_changeset/2)
  end

  # Private

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> validate_length(field, min: 1, max: 255)
  end

  defp validate_ip_address(%Ecto.Changeset{valid?: true} = changeset) do
    with {_, raw_ip} <- fetch_field(changeset, :ip_address),
         {:ok, ip_address} <- InetCidr.parse_address(raw_ip),
         true <- public_ip?(ip_address) do
      put_change(changeset, :ip_address, to_string(:inet.ntoa(ip_address)))
    else
      _ -> delete_change(changeset, :ip_address)
    end
  end

  defp validate_ip_address(changeset), do: changeset

  defp validate_user_agent(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:user_agent)
    |> validate_length(:user_agent, min: 1, max: 1024)
  end

  defp public_ip?(ip_address) do
    case ip_address do
      {10, _, _, _} -> false
      {192, 168, _, _} -> false
      {172, second, _, _} when second >= 16 and second <= 31 -> false
      {127, 0, 0, _} -> false
      {_, _, _, _} -> true
      :einval -> false
      _ -> false
    end
  end

  @metadata_fields ~w(
    before
    after
    attrs
  )a

  defp metadata_changeset(%__MODULE__.Metadata{} = metadata, attrs) do
    metadata
    |> cast(attrs, @metadata_fields)
    |> ChangesetExt.ensure_property_map(:before)
    |> ChangesetExt.ensure_property_map(:after)
    |> ChangesetExt.ensure_property_map(:attrs)
  end
end
