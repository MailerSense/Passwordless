defmodule Passwordless.Actor do
  @moduledoc """
  An actor.
  """

  use Passwordless.Schema, prefix: "user"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Action
  alias Passwordless.App
  alias Passwordless.Email
  alias Passwordless.Locale
  alias Passwordless.Phone
  alias Passwordless.RecoveryCodes
  alias Passwordless.TOTP

  @states ~w(active locked)a
  @languages ~w(en de fr)a

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :state,
             :language,
             :totps,
             :emails,
             :phones,
             :properties,
             :inserted_at,
             :updated_at,
             :deleted_at
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id, :search, :state],
    sortable: [:id, :name, :state, :email, :phone, :inserted_at],
    custom_fields: [
      search: [
        filter: {__MODULE__, :unified_search_filter, []},
        ecto_type: :string
      ]
    ],
    adapter_opts: [
      join_fields: [
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
  schema "actors" do
    field :name, :string
    field :state, Ecto.Enum, values: @states, default: :active
    field :user_id, :string
    field :language, Ecto.Enum, values: Locale.language_codes(), default: :en
    field :properties, :map, default: %{}
    field :properties_text, :string, virtual: true

    field :active, :boolean, default: true, virtual: true

    has_one :email, Email, where: [primary: true]
    has_one :phone, Phone, where: [primary: true]

    has_one :recovery_codes, RecoveryCodes

    has_many :totps, TOTP
    has_many :emails, Email
    has_many :phones, Phone
    has_many :actions, Action

    timestamps()
    soft_delete_timestamp()
  end

  def states, do: @states

  def languages, do: @languages

  @doc """
  Get the handle of the actor.
  """
  def handle(%__MODULE__{name: name}) when is_binary(name), do: name
  def handle(%__MODULE__{email: %Email{address: address}}) when is_binary(address), do: address

  def handle(%__MODULE__{phone: %Phone{canonical: canonical}}) when is_binary(canonical), do: canonical

  def handle(%__MODULE__{user_id: user_id}) when is_binary(user_id), do: user_id
  def handle(%__MODULE__{id: id}) when is_binary(id), do: id
  def handle(%__MODULE__{}), do: nil

  def email(%__MODULE__{email: %Email{address: address}}) when is_binary(address), do: address
  def email(%__MODULE__{}), do: nil

  def phone(%__MODULE__{phone: %Phone{} = phone}), do: Phone.format(phone)
  def phone(%__MODULE__{}), do: nil

  def phone_region(%__MODULE__{phone: %Phone{region: region}}) when is_binary(region), do: String.downcase(region)

  def phone_region(%__MODULE__{}), do: nil

  @doc """
  Get none.
  """
  def get_none(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Database.Tenant.to_prefix(app), where: false
  end

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Database.Tenant.to_prefix(app)
  end

  @doc """
  Preload associations.
  """
  def preload_details(query \\ __MODULE__) do
    from q in query, preload: [:email, :phone]
  end

  def put_active(%__MODULE__{state: state} = actor) do
    %__MODULE__{actor | active: state == :active}
  end

  def put_text_properties(%__MODULE__{properties: properties} = actor) do
    case Jason.encode(properties, pretty: true) do
      {:ok, value} -> %__MODULE__{actor | properties_text: value}
      _ -> actor
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
        where: e.actor_id == parent_as(:actor).id and e.primary,
        select: %{email: e.address}

    phone =
      from p in Phone,
        prefix: ^prefix,
        where: p.actor_id == parent_as(:actor).id and p.primary,
        select: %{phone: p.canonical}

    query =
      if has_named_binding?(query, :actor),
        do: query,
        else: from(q in query, as: :actor)

    from q in query,
      left_lateral_join: e in subquery(email),
      on: true,
      as: :email,
      left_lateral_join: p in subquery(phone),
      on: true,
      as: :phone
  end

  @fields ~w(
    name
    state
    language
    user_id
    properties
    properties_text
    active
  )a
  @required_fields ~w(
    state
    language
    properties
    active
  )a

  @doc """
  A create changeset.
  """
  def create_changeset(%__MODULE__{} = contact, attrs \\ %{}, opts \\ []) do
    contact
    |> cast(attrs, @fields)
    |> validate_required(@required_fields ++ [:name])
    |> validate_name()
    |> validate_user_id(opts)
    |> validate_text_properties()
    |> validate_properties()
    |> cast_assoc(:emails,
      sort_param: :email_sort,
      drop_param: :email_drop
    )
    |> cast_assoc(:phones,
      sort_param: :phone_sort,
      drop_param: :phone_drop,
      with: &Phone.regional_changeset/2
    )
  end

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = contact, attrs \\ %{}, opts \\ []) do
    contact
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_active()
    |> validate_user_id(opts)
    |> validate_text_properties()
    |> validate_properties()
  end

  @doc """
  A properties changeset.
  """
  def properties_changeset(%__MODULE__{} = contact, attrs \\ %{}, opts \\ []) do
    contact
    |> cast(attrs, [:properties_text])
    |> validate_required([:properties_text])
    |> validate_text_properties()
    |> validate_properties()
  end

  @doc """
  A unified search filter.
  """
  def unified_search_filter(query, %Flop.Filter{value: value} = _flop_filter, _) do
    value = "%#{value}%"

    query =
      if has_named_binding?(query, :actor),
        do: query,
        else: from(q in query, as: :actor)

    query =
      query
      |> join_assoc(:email)
      |> join_assoc(:phone)

    where(
      query,
      [actor: a, email: e, phone: p],
      ilike(a.name, ^value) or
        ilike(a.user_id, ^value) or
        ilike(fragment("?::text", a.properties), ^value) or
        ilike(e.email, ^value) or
        ilike(p.phone, ^value)
    )
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 512)
  end

  defp validate_active(changeset) do
    case {get_field(changeset, :state), fetch_change(changeset, :active)} do
      {:active, {:ok, false}} -> put_change(changeset, :state, :locked)
      {:locked, {:ok, true}} -> put_change(changeset, :state, :active)
      _ -> changeset
    end
  end

  defp validate_user_id(changeset, opts) do
    changeset
    |> ChangesetExt.ensure_trimmed(:user_id)
    |> validate_length(:user_id, max: 1024)
    |> unique_constraint(:user_id)
    |> unsafe_validate_unique(:user_id, Passwordless.Repo, prefix: Keyword.get(opts, :prefix))
  end

  defp validate_properties(changeset) do
    changeset
    |> update_change(:properties, fn
      properties when is_map(properties) ->
        (changeset.data.properties || %{})
        |> Map.merge(properties)
        |> Util.cast_property_map()

      properties ->
        properties
    end)
    |> ChangesetExt.validate_property_map(:properties)
  end

  defp validate_text_properties(changeset) do
    case fetch_field(changeset, :properties_text) do
      {_, value} when is_binary(value) ->
        case Jason.decode(value) do
          {:ok, properties} ->
            changeset
            |> put_change(:properties, properties)
            |> put_change(:properties_text, Jason.encode!(properties, pretty: true))

          _ ->
            add_error(changeset, :properties_text, "is invalid JSON")
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
end
