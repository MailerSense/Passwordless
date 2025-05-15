defmodule Passwordless.ActionTemplate do
  @moduledoc false

  use Passwordless.Schema, prefix: "action"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Database.Tenant
  alias Passwordless.Action
  alias Passwordless.ActionStatistic
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
    sortable: [:id, :attempts, :allow_rate, :inserted_at],
    custom_fields: [
      search: [
        filter: {__MODULE__, :unified_search_filter, []},
        ecto_type: :string
      ]
    ],
    adapter_opts: [
      join_fields: [
        attempts: [
          binding: :attempts,
          field: :attempts,
          ecto_type: :integer
        ],
        allow_rate: [
          binding: :attempts,
          field: :allow_rate,
          ecto_type: :float
        ]
      ]
    ]
  }
  schema "action_templates" do
    field :name, :string
    field :alias, :string
    field :attempts, :integer, virtual: true, default: 0
    field :allows, :integer, virtual: true, default: 0
    field :timeouts, :integer, virtual: true, default: 0
    field :blocks, :integer, virtual: true, default: 0
    field :allow_rate, :float, virtual: true, default: 0.0

    embeds_many :rules, Rule, on_replace: :delete do
      @derive Jason.Encoder

      field :enabled, :boolean, default: true
      field :index, :integer, default: 0
      field :condition, :map
      field :effects, :map
    end

    has_one :statistic, ActionStatistic

    has_many :actions, Action, preload_order: [desc: :inserted_at]

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Join the adapter opts.
  """
  def join_adapter_opts(query \\ __MODULE__, opts \\ []) do
    attempts =
      from s in ActionStatistic,
        prefix: ^Keyword.get(opts, :prefix, "public"),
        where: s.action_template_id == parent_as(:template).id,
        select: %{
          attempts: coalesce(s.attempts, 0),
          allows: coalesce(s.allows, 0),
          timeouts: coalesce(s.timeouts, 0),
          blocks: coalesce(s.blocks, 0),
          allow_rate:
            fragment(
              "CASE WHEN ? > 0 THEN ?::float / ?::float ELSE 0 END",
              coalesce(s.allows, 0),
              coalesce(s.allows, 0),
              coalesce(s.attempts, 0)
            )
        }

    query =
      if has_named_binding?(query, :template),
        do: query,
        else: from(q in query, as: :template)

    from q in query,
      left_lateral_join: ac in subquery(attempts),
      on: true,
      as: :attempts,
      select_merge: map(ac, [:attempts, :allows, :timeouts, :blocks, :allow_rate])
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
    |> name_to_alias(opts)
    |> validate_alias(opts)
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 64)
  end

  defp name_to_alias(changeset, opts) do
    case get_change(changeset, :name) do
      name when is_binary(name) ->
        code_alias = Recase.to_camel(name)

        code_alias =
          Util.generate_until(
            code_alias,
            fn _prev -> code_alias <> Util.random_numeric_string(2) end,
            fn code_alias ->
              Passwordless.Repo.exists?(
                from __MODULE__,
                  prefix: ^Keyword.get(opts, :prefix, "public"),
                  where: [alias: ^code_alias]
              )
            end
          )

        put_change(changeset, :alias, code_alias)

      _ ->
        changeset
    end
  end

  defp validate_alias(changeset, opts) do
    changeset
    |> validate_required(:alias)
    |> ChangesetExt.ensure_trimmed(:alias)
    |> validate_length(:alias, min: 1, max: 64)
    |> unique_constraint(:alias)
    |> unsafe_validate_unique(:alias, Passwordless.Repo, opts)
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
