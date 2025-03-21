defmodule Database.SoftDelete do
  @moduledoc """
  Adds soft delete functions to an repository.

      defmodule Repo do
        use Ecto.Repo,
          otp_app: :my_app,
          adapter: Ecto.Adapters.Postgres
        use Ecto.SoftDelete.Repo
      end

  """

  @doc """
  Soft deletes all entries matching the given query.

  It returns a tuple containing the number of entries and any returned
  result as second element. The second element is `nil` by default
  unless a `select` is supplied in the update query.

  ## Examples

      MyRepo.soft_delete_all(Post)
      from(p in Post, where: p.id < 10) |> MyRepo.soft_delete_all()

  """
  @callback soft_delete_all(queryable :: Ecto.Queryable.t()) :: {integer, nil | [term]}

  @doc """
  Soft deletes a struct.
  Updates the `deleted_at` field with the current datetime in UTC.
  It returns `{:ok, struct}` if the struct has been successfully
  soft deleted or `{:error, changeset}` if there was a validation
  or a known constraint error.

  ## Examples

      post = MyRepo.get!(Post, 42)
      case MyRepo.soft_delete post do
        {:ok, struct}       -> # Soft deleted with success
        {:error, changeset} -> # Something went wrong
      end

  """
  @callback soft_delete(struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(), opts :: keyword()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  @doc """
  Same as `c:soft_delete/1` but returns the struct or raises if the changeset is invalid.
  """
  @callback soft_delete!(struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(), opts :: keyword()) ::
              Ecto.Schema.t()

  defmacro __using__(_opts) do
    quote do
      import Ecto.Query

      def soft_delete_all(queryable) do
        update_all(queryable, set: [deleted_at: DateTime.utc_now()])
      end

      def soft_delete(struct_or_changeset, opts \\ []) do
        struct_or_changeset
        |> Ecto.Changeset.change(deleted_at: DateTime.utc_now())
        |> __MODULE__.update(opts)
      end

      def soft_delete!(struct_or_changeset, opts \\ []) do
        struct_or_changeset
        |> Ecto.Changeset.change(deleted_at: DateTime.utc_now())
        |> __MODULE__.update!(opts)
      end

      @doc """
      Overrides all query operations to exclude soft deleted records
      if the schema in the from clause has a deleted_at column
      NOTE: will not exclude soft deleted records if :with_deleted option passed as true
      """
      @impl Ecto.Repo
      def prepare_query(_operation, query, opts) do
        schema_module = get_schema_module_from_query(query)
        fields = if schema_module, do: schema_module.__schema__(:fields), else: []

        cond do
          opts[:prefix] == "oban" ->
            {query, opts}

          opts[:with_deleted] ->
            {query, opts}

          has_include_deleted_at_clause?(query) ->
            {query, opts}

          deletion_disabled_for_process?() ->
            {query, opts}

          not Enum.member?(fields, :deleted_at) ->
            {query, opts}

          true ->
            {from(x in query, where: is_nil(x.deleted_at)), opts}
        end
      end

      def with_soft_deleted(fun) when is_function(fun, 0) do
        Process.put(:with_deleted, true)
        fun.()
      after
        Process.put(:with_deleted, false)
      end

      # Private

      # Checks the query to see if it contains a where not is_nil(deleted_at)
      # if it does, we want to be sure that we don't exclude soft deleted records
      defp has_include_deleted_at_clause?(%Ecto.Query{wheres: wheres}) do
        Enum.any?(wheres, fn %{expr: expr} ->
          expr
          |> Inspect.Algebra.to_doc(%Inspect.Opts{
            inspect_fun: fn expr, _ ->
              inspect(expr, limit: :infinity)
            end
          })
          |> String.contains?("{:not, [], [{:is_nil, [], [{{:., [], [{:&, [], [0]}, :deleted_at]}, [], []}]}]}")
        end)
      end

      defp get_schema_module_from_query(%Ecto.Query{from: %{source: {_name, module}}}) do
        module
      end

      defp get_schema_module_from_query(_), do: nil

      defp deletion_disabled_for_process? do
        Process.get(:with_deleted, false)
      end
    end
  end

  def allow_deleted_records do
    Process.put(:with_deleted, true)
  end

  def disallow_deleted_records do
    Process.put(:with_deleted, false)
  end
end

defmodule Database.SoftDelete.Schema do
  @moduledoc """
  Contains schema macros to add soft delete fields to a schema
  """

  @doc """
  Adds the deleted_at column to a schema
  """
  defmacro soft_delete_timestamp do
    quote do
      field :deleted_at, :utc_datetime_usec
    end
  end
end

defmodule Database.SoftDelete.Migration do
  @moduledoc """
  Contains schema macros to add soft delete fields to a schema
  """

  use Ecto.Migration

  @doc """
  Adds the deleted_at column to a table
  """
  def soft_delete_column do
    add :deleted_at, :utc_datetime_usec
  end
end
