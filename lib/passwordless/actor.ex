defmodule Passwordless.Actor do
  @moduledoc """
  An actor acts.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Action
  alias Passwordless.Locale
  alias Passwordless.Project

  @states ~w(healthy warning locked)a
  @derive {
    Flop.Schema,
    filterable: [:id, :search, :state],
    sortable: [:id, :name, :state, :email, :phone, :locale, :inserted_at],
    custom_fields: [
      search: [
        filter: {__MODULE__, :unified_search_filter, []},
        ecto_type: :string
      ]
    ],
    adapter_opts: [
      compound_fields: [name: [:first_name, :last_name]]
    ]
  }
  schema "actors" do
    field :name, :string, virtual: true
    field :email, :string
    field :phone, :string
    field :state, Ecto.Enum, values: @states, default: :healthy
    field :locale, Ecto.Enum, values: Locale.language_keys(), default: :us
    field :first_name, :string
    field :last_name, :string
    field :custom_id, :string
    field :custom_properties, :map

    has_many :actions, Action

    belongs_to :project, Project, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  def states, do: @states

  @doc """
  Get the full name of the contact.
  """
  def name(%__MODULE__{first_name: f, last_name: l}) when is_binary(f) and is_binary(l), do: "#{f} #{l}"

  def name(%__MODULE__{first_name: f, last_name: nil}) when is_binary(f), do: f
  def name(%__MODULE__{first_name: nil, last_name: l}) when is_binary(l), do: l
  def name(%__MODULE__{}), do: nil

  @doc """
  Get all contacts for an organization.
  """
  def get_by_project(query \\ __MODULE__, %Project{} = project) do
    from q in query, where: q.project_id == ^project.id
  end

  @doc """
  Get none.
  """
  def get_none(query \\ __MODULE__) do
    from q in query, where: false
  end

  @fields ~w(
    email
    phone
    state
    locale
    first_name
    last_name
    custom_id
    custom_properties
    project_id
  )a
  @required_fields ~w(
    state
    locale
    project_id
  )a

  @doc """
  A contact changeset.
  """
  def changeset(%__MODULE__{} = contact, attrs \\ %{}) do
    contact
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_email()
    |> validate_phone()
    |> validate_custom_id()
    |> validate_custom_properties()
    |> unique_constraint([:project_id, :email], error_key: :email)
    |> unique_constraint([:project_id, :phone], error_key: :phone)
    |> unique_constraint([:project_id, :custom_id], error_key: :custom_id)
    |> unsafe_validate_unique([:project_id, :email], Passwordless.Repo, error_key: :email)
    |> unsafe_validate_unique([:project_id, :phone], Passwordless.Repo, error_key: :phone)
    |> unsafe_validate_unique([:project_id, :custom_id], Passwordless.Repo, error_key: :email)
    |> assoc_constraint(:project)
  end

  def unified_search_filter(query, %Flop.Filter{value: value} = _flop_filter, _) do
    value = "%#{value}%"

    where(
      query,
      [c],
      ilike(fragment("concat(?, ' ', ?)", c.first_name, c.last_name), ^value) or
        ilike(c.email, ^value) or
        ilike(c.phone, ^value) or
        ilike(c.custom_id, ^value) or
        ilike(fragment("?::text", c.custom_properties), ^value)
    )
  end

  def unified_search(query \\ __MODULE__, value) do
    value = "%#{value}%"

    where(
      query,
      [c],
      ilike(fragment("concat(?, ' ', ?)", c.first_name, c.last_name), ^value) or
        ilike(c.email, ^value) or
        ilike(c.phone, ^value)
    )
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:first_name)
    |> ChangesetExt.ensure_trimmed(:last_name)
    |> validate_length(:first_name, min: 1, max: 160)
    |> validate_length(:last_name, min: 1, max: 160)
  end

  defp validate_phone(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:phone)
    |> validate_length(:phone, min: 1, max: 160)
  end

  defp validate_email(changeset) do
    ChangesetExt.validate_email(changeset, :email)
  end

  defp validate_custom_id(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:custom_id)
    |> validate_length(:custom_id, max: 512)
  end

  defp validate_custom_properties(changeset) do
    changeset
    |> update_change(:custom_properties, fn
      custom_properties when is_map(custom_properties) ->
        (changeset.data.custom_properties || %{})
        |> Map.merge(custom_properties)
        |> Util.cast_property_map()

      custom_properties ->
        custom_properties
    end)
    |> ChangesetExt.validate_property_map(:custom_properties)
  end
end
