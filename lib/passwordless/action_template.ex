defmodule Passwordless.ActionTemplate do
  @moduledoc false

  use Passwordless.Schema, prefix: "action"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Database.Tenant
  alias Passwordless.Action
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
    sortable: [:id, :action_count, :inserted_at],
    custom_fields: [
      search: [
        filter: {__MODULE__, :unified_search_filter, []},
        ecto_type: :string
      ]
    ],
    adapter_opts: [
      join_fields: [
        action_count: [
          binding: :action_count,
          field: :count,
          ecto_type: :integer
        ]
      ]
    ]
  }
  schema "action_templates" do
    field :name, :string
    field :alias, :string

    field :action_count, :integer, virtual: true, default: 0

    embeds_many :rules, Rule, on_replace: :delete do
      @derive Jason.Encoder

      field :enabled, :boolean, default: true
      field :index, :integer, default: 0
      field :condition, :map
      field :effects, :map
    end

    has_many :actions, Action, preload_order: [desc: :inserted_at]

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Join the adapter opts.
  """
  def join_adapter_opts(query \\ __MODULE__, opts \\ []) do
    action_count =
      from a in Action,
        prefix: ^Keyword.get(opts, :prefix, "public"),
        where: a.template_id == parent_as(:template).id,
        select: %{count: count(a.id)}

    query =
      if has_named_binding?(query, :template),
        do: query,
        else: from(q in query, as: :template)

    from q in query,
      left_lateral_join: ac in subquery(action_count),
      on: true,
      as: :action_count,
      select_merge: %{action_count: ac.count}
  end

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
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
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action_template, attrs \\ %{}, opts \\ []) do
    action_template
    |> cast(attrs, @fields)
    |> cast_embed(:rules,
      with: &rule_changeset/2,
      sort_param: :rules_sort,
      drop_param: :rules_drop,
      required: true
    )
    |> validate_required(@required_fields)
    |> validate_name()
    |> put_alias()
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

  @rule_fields ~w(
    enabled
    index
    condition
    effects
  )a
  @rule_required_fields @rule_fields

  defp rule_changeset(%__MODULE__.Rule{} = rule, attrs) do
    rule
    |> cast(attrs, @rule_fields)
    |> validate_required(@rule_required_fields)
  end
end
