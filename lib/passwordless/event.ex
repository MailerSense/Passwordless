defmodule Passwordless.Event do
  @moduledoc """
  An avent.
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
    field :device_type, :string
    field :language, :string
    field :city, :string
    field :region, :string
    field :country, :string
    field :latitude, :float
    field :longitude, :float
    field :timezone, :string

    belongs_to :user, User
    belongs_to :action, Action

    timestamps(updated_at: false)
  end

  @fields ~w(
    event
    ip_address
    user_agent
    browser
    browser_version
    operating_system
    operating_system_version
    device_type
    language
    city
    region
    country
    latitude
    longitude
    timezone
    user_id
    action_id
  )a
  @required_fields ~w(
    event
    user_id
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
    |> validate_string(:browser)
    |> validate_string(:browser_version)
    |> validate_string(:operating_system)
    |> validate_string(:operating_system_version)
    |> validate_string(:device_type)
    |> validate_string(:language)
    |> validate_string(:city)
    |> validate_string(:region)
    |> validate_string(:country)
    |> validate_string(:timezone)
    |> validate_number(:latitude, greater_than: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than: -180, less_than_or_equal_to: 180)
    |> validate_string(:timezone)
    |> assoc_constraint(:user)
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
        region: fn data ->
          case {get_in(data, ["country", "iso_code"]), get_in(data, ["subdivisions", Access.at(0), "iso_code"])} do
            {country, region} when is_binary(country) and is_binary(region) -> "#{country}-#{region}"
            _ -> nil
          end
        end,
        country: ["country", "iso_code"],
        latitude: ["location", "latitude"],
        longitude: ["location", "longitude"],
        timezone: ["location", "time_zone"]
      ]

      Enum.reduce(paths, changeset, fn
        {key, path}, acc when is_list(path) ->
          case get_in(geo_data, path) do
            value when is_binary(value) or is_number(value) -> put_change(acc, key, value)
            _ -> acc
          end

        {key, path}, acc when is_function(path, 1) ->
          case path.(geo_data) do
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
      paths = [
        browser: [Access.key(:client), Access.key(:name)],
        browser_version: [Access.key(:client), Access.key(:version)],
        operating_system: [Access.key(:os), Access.key(:name)],
        operating_system_version: [Access.key(:os), Access.key(:version)],
        device_type: [Access.key(:device), Access.key(:type)]
      ]

      Enum.reduce(paths, changeset, fn {key, path}, acc ->
        case get_in(result, path) do
          value when is_binary(value) or is_number(value) -> put_change(acc, key, value)
          _ -> acc
        end
      end)
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
