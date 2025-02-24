defmodule Passwordless.Actor do
  @moduledoc """
  An actor acts.
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

  @states ~w(active stale)a
  @derive {
    Flop.Schema,
    filterable: [:id, :search, :state],
    sortable: [:id, :name, :state],
    custom_fields: [
      search: [
        filter: {__MODULE__, :unified_search_filter, []},
        ecto_type: :string
      ]
    ],
    adapter_opts: []
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
  A changeset.
  """
  def changeset(%__MODULE__{} = contact, attrs \\ %{}) do
    contact
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> assoc_constraint(:app)
  end

  def unified_search_filter(query, %Flop.Filter{value: value} = _flop_filter, _) do
    value = "%#{value}%"

    where(
      query,
      [c],
      ilike(fragment("concat(?, ' ', ?)", c.first_name, c.last_name), ^value) or
        ilike(c.email, ^value) or
        ilike(c.phone, ^value) or
        ilike(c.user_id, ^value)
    )
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 512)
  end
end
