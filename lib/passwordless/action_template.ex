defmodule Passwordless.ActionTemplate do
  @moduledoc false

  use Passwordless.Schema, prefix: "action"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.App

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id, :search],
    sortable: [:id, :inserted_at],
    custom_fields: [
      search: [
        filter: {__MODULE__, :unified_search_filter, []},
        ecto_type: :string
      ]
    ]
  }
  schema "action_templates" do
    field :name, :string
    field :alias, :string

    belongs_to :app, App

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, where: q.app_id == ^app.id
  end

  @doc """
  A unified search filter.
  """
  def unified_search_filter(query, %Flop.Filter{value: value} = _flop_filter, _) do
    value = "%#{value}%"
    where(query, [a], ilike(a.name, ^value) or ilike(a.alias, ^value))
  end

  @fields ~w(
    name
    app_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action_template, attrs \\ %{}, opts \\ []) do
    action_template
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> put_alias()
    |> assoc_constraint(:app)
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 255)
  end

  defp put_alias(changeset) do
    if value = get_field(changeset, :name) do
      put_change(changeset, :alias, Recase.to_camel(value))
    else
      changeset
    end
  end
end
