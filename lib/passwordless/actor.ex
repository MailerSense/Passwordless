defmodule Passwordless.Actor do
  @moduledoc """
  An actor.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Action
  alias Passwordless.App
  alias Passwordless.Challenge
  alias Passwordless.Email
  alias Passwordless.Identity
  alias Passwordless.Locale
  alias Passwordless.Phone
  alias Passwordless.RecoveryCodes
  alias Passwordless.TOTP

  @states ~w(active locked stale)a
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
             :identities
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
    field :language, Ecto.Enum, values: Locale.language_codes(), default: :en

    field :active, :boolean, default: true, virtual: true

    has_one :email, Email, where: [primary: true]
    has_one :phone, Phone, where: [primary: true]

    has_one :recovery_codes, RecoveryCodes

    has_many :totps, TOTP
    has_many :emails, Email
    has_many :phones, Phone
    has_many :actions, Action
    has_many :identities, Identity
    has_many :challenges, Challenge

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
  def handle(%__MODULE__{}), do: nil

  def email(%__MODULE__{email: %Email{address: address}}) when is_binary(address), do: address
  def email(%__MODULE__{}), do: nil

  def phone(%__MODULE__{phone: %Phone{canonical: canonical}}) when is_binary(canonical), do: canonical
  def phone(%__MODULE__{}), do: nil

  def phone_region(%__MODULE__{phone: %Phone{region: region}}) when is_binary(region), do: String.downcase(region)
  def phone_region(%__MODULE__{}), do: nil

  @doc """
  Get none.
  """
  def get_none(query \\ __MODULE__) do
    from q in query, where: false
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
    active
  )a
  @required_fields ~w(
    state
    language
    active
  )a

  @doc """
  A create changeset.
  """
  def create_changeset(%__MODULE__{} = contact, attrs \\ %{}) do
    contact
    |> cast(attrs, @fields)
    |> validate_required(@required_fields ++ [:name])
    |> validate_name()
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
  def changeset(%__MODULE__{} = contact, attrs \\ %{}) do
    contact
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_active()
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
      |> join_assoc(:identities)

    where(
      query,
      [actor: a, email: e, phone: p, identities: i],
      ilike(a.name, ^value) or
        ilike(e.email, ^value) or
        ilike(p.phone, ^value) or
        ilike(i.user_id, ^value)
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

  defp join_assoc(query, binding) do
    if has_named_binding?(query, binding),
      do: query,
      else: join(query, :left, [l], assoc(l, ^binding), as: ^binding)
  end
end
