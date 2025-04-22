defmodule Database.QueryExt do
  @moduledoc """
  Helpful query functions. Similar to the QueryBuilder lib, but for cases where you don't want to use QueryBuilder.
  """
  import Ecto.Query
  import SqlFmt.Helpers

  alias Database.Tenant
  alias Passwordless.App

  @doc """
  Limit a the number of results from a query. Can be compined with other queryables
  UserQuery.text_search("Matt") |> QueryExt.limit(query, 5)
  """
  def limit(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    offset = Keyword.get(opts, :offset, 0)

    from(x in query, limit: ^limit, offset: ^offset)
  end

  @doc """
  Preload associations.
  UserQuery.text_search("Matt") |> QueryExt.preload(:posts) |> Repo.all()
  """
  def preload(query, preloads) do
    from(x in query,
      preload: ^preloads
    )
  end

  @doc """
  Construct a where query on the fly. Only works when `use QueryBuilder` is added to the schema file
  eg QueryExt.where(Log, %{post_id: 1814, user_id: 24688, user_type: "user"}) |> Repo.all()
  """
  def where(query, params) do
    Enum.reduce(params, query, fn {key, value}, q ->
      QueryBuilder.where(q, {key, value})
    end)
  end

  @doc """
  order_by(query, [:name, :population])
  order_by(query, [asc: :name, desc_nulls_first: :population])
  """
  def order_by(query, order) do
    from(x in query, order_by: ^order)
  end

  @doc "Order by newest first"
  def order_newest_first(query) do
    from(x in query,
      order_by: [desc: x.id]
    )
  end

  @doc "Order by oldest first"
  def order_oldest_first(query) do
    from(x in query,
      order_by: [asc: x.inserted_at, asc: x.id]
    )
  end

  @doc """
  Get all entities by app.
  """
  def get_by_app(query, %App{} = app) do
    from q in query, where: q.app_id == ^app.id
  end

  @doc """
  Get none.
  """
  def get_none(query) do
    from q in query, where: false
  end

  @doc """
  Get the estimate count of rows in an Ecto schema
  """
  def count_estimate(%App{} = app, schema) do
    result =
      Ecto.Adapters.SQL.query!(
        Passwordless.Repo,
        ~SQL"SELECT reltuples AS estimate FROM pg_class WHERE relname = $1",
        [schema.__schema__(:source)],
        prefix: Tenant.to_prefix(app)
      )

    case result do
      %Postgrex.Result{columns: ["estimate"], rows: [[estimate]]} when is_number(estimate) ->
        trunc(estimate)

      _ ->
        0
    end
  end

  @doc "Join an association if it does not exist"
  def join_assoc(query, binding) do
    if has_named_binding?(query, binding),
      do: query,
      else: join(query, :left, [l], assoc(l, ^binding), as: ^binding)
  end

  @doc """
  PostgreSQL's `coalesce` function

  Use `coalesce/2` to return the first argument that is not null.

  ```
  from(posts in "posts",
  select: {
    posts.title,
    coalesce(posts.short_description, posts.description)
  })
  ```

  """
  defmacro coalesce(left, right) do
    quote do
      fragment("coalesce(?, ?)", unquote(left), unquote(right))
    end
  end

  @doc """
  PostgreSQL's `coalesce` function

  Use `coalesce/1` to return the first value in the given list that is not
  null.

  ```
  from(posts in "posts",
  select: {
    posts.title,
    coalesce([posts.short_description, posts.description, "N/A"])
  })
  ```

  """
  defmacro coalesce(operands) do
    fragment_str = "coalesce(" <> generate_question_marks(operands) <> ")"
    {:fragment, [], [fragment_str | operands]}
  end

  @doc """
  PostgreSQL's `nullif` function

  Use `nullif/2` to return null if the two arguments are equal.

  ```
  from(posts in "posts",
  select: nullif(posts.description, ""))
  ```

  This is a peculiar function, but can be handy in combination with other
  functions. For example, use it within `coalesce/1` to weed out a blank
  value and replace it with some default.

  ```
  from(posts in "posts",
  select: {
    posts.title,
    coalesce(nullif(posts.description, ""), "N/A")
  })
  ```

  """
  defmacro nullif(left, right) do
    quote do
      fragment("nullif(?, ?)", unquote(left), unquote(right))
    end
  end

  @doc """
  PostgreSQL's `greatest` function

  Use `greatest/2` to return the larger of two arguments. This function will
  always preference actual values over null.

  ```
  from(posts in "posts",
  select: greatest(posts.created_at, posts.published_at))
  ```
  """
  defmacro greatest(left, right) do
    quote do
      fragment("greatest(?, ?)", unquote(left), unquote(right))
    end
  end

  @doc """
  PostgreSQL's `greatest` function

  Use `greatest/1` to return the largest of a list of arguments. This
  function will always preference actual values over null.

  ```
  from(posts in "posts",
  select: greatest([
                     posts.created_at,
                     posts.updated_at,
                     posts.published_at
                   ]))
  ```

  """
  defmacro greatest(operands) do
    fragment_str = "greatest(" <> generate_question_marks(operands) <> ")"
    {:fragment, [], [fragment_str | operands]}
  end

  @doc """
  PostgreSQL's `least` function

  Use `least/2` to return the smaller of the two arguments. This function
  always preferences actual values over null.

  ```
  from(posts in "posts",
  select: least(posts.created_at, posts.updated_at))
  ```

  """
  defmacro least(left, right) do
    quote do
      fragment("least(?, ?)", unquote(left), unquote(right))
    end
  end

  @doc """
  PostgreSQL's `least` function

  Use `least/1` to return the smallest of the arguments. This function
  always preferences actual values over null.

  ```
  from(posts in "posts",
  select: least([
                  posts.created_at,
                  posts.updated_at,
                  posts.published_at
                ]))
  ```

  """
  defmacro least(operands) do
    fragment_str = "least(" <> generate_question_marks(operands) <> ")"
    {:fragment, [], [fragment_str | operands]}
  end

  @doc """
  PostgreSQL's `lower` function

  Use `lower/1` to lowercase a given string. This works like Elixir's
  `String.downcase/1` function allowing string manipulation within a query.

  ```
  from(users in "users",
  select: lower(users.email))
  ```

  """
  defmacro lower(operand) do
    quote do
      fragment("lower(?)", unquote(operand))
    end
  end

  @doc """
  PostgreSQL's `upper` function

  Use `upper/1` to uppercase a given string. This works like Elixir's
  `String.upcase/1` function allowing string manipulation within a query.

  ```
  from(users in "users",
  select: upper(users.username))
  ```

  """
  defmacro upper(operand) do
    quote do
      fragment("upper(?)", unquote(operand))
    end
  end

  @doc """
  PostgreSQL's `contains` operator
  Use `contains/2` to check if the first argument contains the second
  argument. This is useful for checking if a JSONB column contains a
  specific key or value.

  ```
  from(posts in "posts",
  where: contains(posts.data, ^"key"))
  ```

  """
  defmacro contains(left, right) do
    quote do
      fragment("? @> ?", unquote(left), unquote(right))
    end
  end

  @doc """
  PostgreSQL's `between` predicate

  Use `between/3` to perform a range test for the first argument against the
  second (lower bound) and third argument (upper bound). Returns true if the
  value falls in the given range. False otherwise.

  ```
  from(posts in "posts",
  select: {posts.title, posts.description}
  where: between(posts.published_at,
                 ^Ecto.DateTime.cast!({{2016,5,10},{0,0,0}}),
                 ^Ecto.DateTime.cast!({{2016,5,20},{0,0,0}})))
  ```

  """
  defmacro between(value, lower, upper) do
    quote do
      fragment(
        "? between ? and ?",
        unquote(value),
        unquote(lower),
        unquote(upper)
      )
    end
  end

  @doc """
  PostgreSQL's `not between` predicate

  Use `not_between/3` to perform a range test for the first argument against
  the second (lower bound) and third argument (upper bound). Returns true if
  the value does not fall in the given range. False otherwise.

  ```
  from(posts in "posts",
  select: {posts.title, posts.description}
  where: not_between(posts.published_at,
                     ^Ecto.DateTime.cast!({{2016,5,10},{0,0,0}}),
                     ^Ecto.DateTime.cast!({{2016,5,20},{0,0,0}})))
  ```

  """
  defmacro not_between(value, lower, upper) do
    quote do
      fragment(
        "? not between ? and ?",
        unquote(value),
        unquote(lower),
        unquote(upper)
      )
    end
  end

  @doc """
  PostgreSQL's `array_length` function
  """
  defmacro array_length(operand) do
    quote do
      fragment("array_length(?, 1)", unquote(operand))
    end
  end

  @doc """
  Returns a query that searches only for undeleted items

      query = from(u in User, select: u)
      |> with_undeleted

      results = Repo.all(query)

  """
  @spec with_undeleted(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  def with_undeleted(query) do
    if soft_deletable?(query) do
      where(query, [t], is_nil(t.deleted_at))
    else
      query
    end
  end

  @doc """
  Returns `true` if the query is soft deletable, `false` otherwise.

      query = from(u in User, select: u)
      |> soft_deletable?

  """
  @spec soft_deletable?(Ecto.Queryable.t()) :: boolean()
  def soft_deletable?(query) do
    schema_module = get_schema_module(query)
    fields = if schema_module, do: schema_module.__schema__(:fields), else: []

    Enum.member?(fields, :deleted_at)
  end

  @doc """
  Returns `true` if the schema is not flagged to skip auto-filtering
  """
  @spec auto_include_deleted_at_clause?(Ecto.Queryable.t()) :: boolean()
  def auto_include_deleted_at_clause?(query) do
    schema_module = get_schema_module(query)

    !Kernel.function_exported?(schema_module, :skip_soft_delete_prepare_query?, 0) ||
      !schema_module.skip_soft_delete_prepare_query?()
  end

  # Private

  defp get_schema_module({_raw_schema, module}) when not is_nil(module), do: module
  defp get_schema_module(%Ecto.Query{from: %{source: source}}), do: get_schema_module(source)
  defp get_schema_module(%Ecto.SubQuery{query: query}), do: get_schema_module(query)
  defp get_schema_module(_), do: nil

  defp generate_question_marks(list) do
    Enum.map_join(list, ", ", fn _ -> "?" end)
  end
end
