defmodule Passwordless.User do
  @moduledoc """
  A user.
  """

  use Passwordless.Schema, prefix: "user"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Database.Tenant
  alias Passwordless.Action
  alias Passwordless.App
  alias Passwordless.Email
  alias Passwordless.Enrollment
  alias Passwordless.Event
  alias Passwordless.Identifier
  alias Passwordless.Locale
  alias Passwordless.Phone
  alias Passwordless.RecoveryCodes
  alias Passwordless.TOTP

  @languages ~w(en de fr)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :language,
      :email,
      :phone,
      :identifier,
      :data,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id, :search],
    sortable: [:id, :email, :phone, :identifier, :inserted_at],
    custom_fields: [
      search: [
        filter: {__MODULE__, :unified_search_filter, []},
        ecto_type: :string
      ]
    ],
    adapter_opts: [
      join_fields: [
        identifier: [
          binding: :identifier,
          field: :identifier,
          ecto_type: :string
        ],
        email: [
          binding: :email,
          field: :email,
          ecto_type: :string
        ],
        phone: [
          binding: :phone,
          field: :phone,
          ecto_type: :string
        ]
      ]
    ]
  }
  schema "users" do
    field :language, Ecto.Enum, values: Locale.language_codes(), default: :en
    field :data, Passwordless.EncryptedMap
    field :data_text, :string, virtual: true

    has_one :email, Email, where: [primary: true]
    has_one :phone, Phone, where: [primary: true]
    has_one :identifier, Identifier, where: [primary: true]

    has_one :recovery_codes, RecoveryCodes

    has_many :totps, TOTP, preload_order: [asc: :inserted_at]
    has_many :emails, Email, preload_order: [asc: :inserted_at]
    has_many :events, Event, preload_order: [asc: :inserted_at]
    has_many :phones, Phone, preload_order: [asc: :inserted_at]
    has_many :actions, Action, preload_order: [asc: :inserted_at]
    has_many :enrollments, Enrollment, preload_order: [asc: :inserted_at]

    timestamps()
    soft_delete_timestamp()
  end

  def languages, do: @languages

  @doc """
  Get the handle of the user.
  """
  def handle(%__MODULE__{email: %Email{address: address}}) when is_binary(address), do: address
  def handle(%__MODULE__{phone: %Phone{canonical: canonical}}) when is_binary(canonical), do: canonical
  def handle(%__MODULE__{phone: %Identifier{value: value}}) when is_binary(value), do: value
  def handle(%__MODULE__{id: id}) when is_binary(id), do: id
  def handle(%__MODULE__{}), do: nil

  @doc """
  Get the primary email of the user.
  """
  def email(%__MODULE__{email: %Email{address: address}}) when is_binary(address), do: address
  def email(%__MODULE__{}), do: nil

  @doc """
  Get the primary phone of the user.
  """
  def phone(%__MODULE__{phone: %Phone{} = phone}), do: Phone.format(phone)
  def phone(%__MODULE__{}), do: nil

  @doc """
  Get the region of the primary phone of the user.
  """
  def phone_region(%__MODULE__{phone: %Phone{region: region}}) when is_binary(region), do: String.downcase(region)
  def phone_region(%__MODULE__{}), do: nil

  @doc """
  Get the primary email of the user.
  """
  def identifier(%__MODULE__{identifier: %Identifier{value: value}}) when is_binary(value), do: value
  def identifier(%__MODULE__{}), do: nil

  @doc """
  Get none.
  """
  def get_none(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app), where: false
  end

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
  end

  @doc """
  Preload associations.
  """
  def preload_details(query \\ __MODULE__) do
    from q in query, preload: [:email, :phone]
  end

  def put_text_data(%__MODULE__{data: data} = user) do
    case Jason.encode(data, pretty: true) do
      {:ok, value} -> %__MODULE__{user | data_text: value}
      _ -> user
    end
  end

  @doc """
  Join the details.
  """
  def join_details(query \\ __MODULE__, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "public")

    email =
      from e in Email,
        prefix: ^prefix,
        where: e.user_id == parent_as(:user).id and e.primary,
        select: %{email: e.address}

    phone =
      from p in Phone,
        prefix: ^prefix,
        where: p.user_id == parent_as(:user).id and p.primary,
        select: %{phone: p.canonical}

    identifier =
      from i in Identifier,
        prefix: ^prefix,
        where: i.user_id == parent_as(:user).id and i.primary,
        select: %{identifier: i.value}

    query =
      if has_named_binding?(query, :user),
        do: query,
        else: from(q in query, as: :user)

    from q in query,
      left_lateral_join: e in subquery(email),
      on: true,
      as: :email,
      left_lateral_join: p in subquery(phone),
      on: true,
      as: :phone,
      left_lateral_join: i in subquery(identifier),
      on: true,
      as: :identifier
  end

  @fields ~w(language data data_text)a
  @required_fields ~w(language data)a

  @doc """
  A create changeset.
  """
  def create_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_text_data()
    |> validate_data()
    |> cast_assoc(:email)
    |> cast_assoc(:phone, with: &Phone.regional_changeset/2)
    |> cast_assoc(:identifier)
  end

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_text_data()
    |> validate_data()
  end

  @doc """
  A unified search filter.
  """
  def unified_search_filter(query, %Flop.Filter{value: value} = _flop_filter, _) do
    query =
      if has_named_binding?(query, :user),
        do: query,
        else: from(q in query, as: :user)

    query =
      query
      |> join_assoc(:email)
      |> join_assoc(:phone)
      |> join_assoc(:identifier)

    pref = prefix()

    id_query =
      case Database.PrefixedUUID.slug_to_uuid(value) do
        {:ok, ^pref, _uuid} -> dynamic([user: u], u.id == ^value)
        _ -> false
      end

    value = "%#{value}%"

    clause =
      [
        dynamic([email: e], ilike(e.email, ^value)),
        dynamic([phone: p], ilike(p.phone, ^value)),
        dynamic([identifier: i], ilike(i.identifier, ^value))
      ]
      |> append_if(id_query, id_query != false)
      |> Enum.reduce(dynamic(false), &dynamic(^&2 or ^&1))

    where(query, ^clause)
  end

  # Private

  defp validate_data(changeset) do
    changeset
    |> update_change(:data, fn
      data when is_map(data) ->
        (changeset.data.data || %{})
        |> Map.merge(data)
        |> Util.cast_property_map()

      data ->
        data
    end)
    |> ChangesetExt.validate_property_map(:data)
  end

  defp validate_text_data(changeset) do
    case fetch_field(changeset, :data_text) do
      {_, value} when is_binary(value) ->
        case Jason.decode(value) do
          {:ok, data} ->
            changeset
            |> put_change(:data, data)
            |> put_change(:data_text, Jason.encode!(data, pretty: true))

          _ ->
            add_error(changeset, :data_text, "is invalid JSON")
        end

      _ ->
        changeset
    end
  end

  defp join_assoc(query, binding) do
    if has_named_binding?(query, binding),
      do: query,
      else: join(query, :left, [l], assoc(l, ^binding), as: ^binding)
  end

  defp append_if(list, _value, false), do: list
  defp append_if(list, value, true), do: list ++ List.wrap(value)
end
