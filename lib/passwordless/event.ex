defmodule Passwordless.Event do
  @moduledoc """
  An avent.
  """

  use Passwordless.Schema, prefix: "event"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Database.Inet
  alias Database.Tenant
  alias Passwordless.Action
  alias Passwordless.ActionTemplate
  alias Passwordless.App
  alias Passwordless.Enrollment
  alias Passwordless.GeoIP
  alias Passwordless.User

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :event,
      :ip_address,
      :user_agent,
      :browser,
      :browser_version,
      :operating_system,
      :operating_system_version,
      :device_type,
      :language,
      :city,
      :region,
      :country,
      :latitude,
      :longitude,
      :timezone,
      :inserted_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "events" do
    field :event, :string
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
    belongs_to :enrollment, Enrollment

    timestamps(updated_at: false)
  end

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
  end

  @doc """
  Preload action.
  """
  def preload_action(query \\ __MODULE__) do
    from q in query, preload: [{:action, [:action_template]}]
  end

  @doc """
  Preload user.
  """
  def preload_user(query \\ __MODULE__) do
    from q in query, preload: :user
  end

  @doc """
  Get by action template.
  """
  def get_by_template(query \\ __MODULE__, %App{} = app, %ActionTemplate{} = action_template) do
    from q in query,
      left_join: a in assoc(q, :action),
      prefix: ^Tenant.to_prefix(app),
      where: a.action_template_id == ^action_template.id
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
        browser: fn
          %UAInspector.Result{client: %UAInspector.Result.Client{name: name}} -> name
          _ -> nil
        end,
        browser_version: fn
          %UAInspector.Result{client: %UAInspector.Result.Client{version: version}} -> version
          _ -> nil
        end,
        operating_system: fn
          %UAInspector.Result{os: %UAInspector.Result.OS{name: name}} -> name
          _ -> nil
        end,
        operating_system_version: fn
          %UAInspector.Result{os: %UAInspector.Result.OS{version: version}} -> version
          _ -> nil
        end,
        device_type: fn
          %UAInspector.Result{device: %UAInspector.Result.Device{type: type}} -> type
          _ -> nil
        end
      ]

      Enum.reduce(paths, changeset, fn {key, path}, acc ->
        case path.(result) do
          value when is_binary(value) or is_number(value) -> put_change(acc, key, value)
          _ -> acc
        end
      end)
    else
      _ -> changeset
    end
  end

  defp put_user_agent_data(%Ecto.Changeset{} = changeset), do: changeset
end
