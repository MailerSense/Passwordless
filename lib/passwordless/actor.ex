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
  alias Passwordless.Locale
  alias Passwordless.Phone
  alias Passwordless.TOTP

  @states ~w(enrolled active stale)a
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

    has_one :email, Email, where: [primary: true]
    has_one :phone, Phone, where: [primary: true]

    has_many :totps, TOTP
    has_many :emails, Email
    has_many :phones, Phone
    has_many :actions, Action
    has_many :challenges, Challenge

    belongs_to :app, App, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  def states, do: @states

  @doc """
  Get the handle of the actor.
  """
  def handle(%__MODULE__{name: name}) when is_binary(name) and not is_nil(name), do: name
  def handle(%__MODULE__{email: %Email{address: address}}) when is_binary(address) and not is_nil(address), do: address
  def handle(%__MODULE__{phone: %Phone{address: address}}) when is_binary(address) and not is_nil(address), do: address
  def handle(%__MODULE__{}), do: nil

  def email(%__MODULE__{email: %Email{address: address}}) when is_binary(address) and not is_nil(address), do: address
  def email(%__MODULE__{}), do: nil

  def phone(%__MODULE__{phone: %Phone{address: address}}) when is_binary(address) and not is_nil(address), do: address
  def phone(%__MODULE__{}), do: nil

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, where: q.app_id == ^app.id
  end

  @doc """
  Get none.
  """
  def get_none(query \\ __MODULE__) do
    from q in query, where: false
  end

  @doc """
  Preload associations.
  """
  def preload_details(query \\ __MODULE__) do
    from q in query, preload: [:email, :phone]
  end

  @doc """
  Join the details.
  """
  def join_details(query \\ __MODULE__) do
    email =
      from e in Email,
        where: e.actor_id == parent_as(:actor).id and e.primary,
        select: %{email: e.address}

    phone =
      from p in Phone,
        where: p.actor_id == parent_as(:actor).id and p.primary,
        select: %{phone: p.address}

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
    app_id
  )a
  @required_fields ~w(
    state
    language
    app_id
  )a

  @doc """
  A create changeset.
  """
  def create_changeset(%__MODULE__{} = contact, attrs \\ %{}) do
    contact
    |> cast(attrs, @fields)
    |> validate_required(@required_fields ++ [:name])
    |> validate_name()
    |> assoc_constraint(:app)
  end

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = contact, attrs \\ %{}) do
    contact
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> assoc_constraint(:app)
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

  defp join_assoc(query, binding) do
    if has_named_binding?(query, binding),
      do: query,
      else: join(query, :left, [l], assoc(l, ^binding), as: ^binding)
  end
end
