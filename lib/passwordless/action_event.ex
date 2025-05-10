defmodule Passwordless.Event do
  @moduledoc """
  An action avent.
  """

  use Passwordless.Schema, prefix: "event"

  alias Database.ChangesetExt
  alias Database.Inet
  alias Passwordless.Action
  alias Passwordless.GeoIP
  alias Passwordless.User

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
  schema "events" do
    field :event, :string

    embeds_one :metadata, Metadata, on_replace: :delete do
      @derive Jason.Encoder

      field :before, :map, default: %{}
      field :after, :map, default: %{}
      field :attrs, :map, default: %{}
    end

    field :ip_address, Inet
    field :user_agent, :string
    field :browser, :string
    field :browser_version, :string
    field :operating_system, :string
    field :operating_system_version, :string
    field :language, :string
    field :city, :string
    field :region, :string
    field :country, :string
    field :country_iso, :string
    field :latitude, :float
    field :longitude, :float
    field :timezone, :string
    field :screen_width, :integer
    field :screen_height, :integer
    field :device_type, :string

    belongs_to :user, User
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
  def changeset(%__MODULE__{} = event, attrs \\ %{}) do
    event
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_ip_address()
    |> validate_user_agent()
    |> put_ip_data()
    |> put_user_agent_data()
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
    with raw_ip when is_binary(raw_ip) <- get_change(changeset, :ip_address),
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

  defp put_ip_data(%Ecto.Changeset{valid?: true} = changeset) do
    with ip when is_binary(ip) <- get_change(changeset, :ip_address),
         {:ok, geo_data} when is_map(geo_data) <- GeoIP.lookup(ip) do
      paths = [
        city: ["city", "names", "en"],
        country: ["country", "names", "en"],
        country_iso: ["country", "isoCode"],
        latitude: ["location", "latitude"],
        longitude: ["location", "longitude"],
        timezone: ["location", "timeZone"]
      ]

      Enum.reduce(paths, changeset, fn {key, path}, acc ->
        case get_in(geo_data, path) do
          value when is_binary(value) or is_number(value) -> put_change(acc, key, value)
          _ -> acc
        end
      end)
    else
      _ -> changeset
    end
  end

  defp put_ip_data(%Ecto.Changeset{} = changeset), do: changeset

  defp put_user_agent_data(%Ecto.Changeset{valid?: true} = changeset) do
    with ua when is_binary(ua) <- get_change(changeset, :user_agent),
         result when is_struct(result) <- UAInspector.parse(ua) do
      changeset
    else
      _ -> changeset
    end
  end

  defp put_user_agent_data(%Ecto.Changeset{} = changeset), do: changeset

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
