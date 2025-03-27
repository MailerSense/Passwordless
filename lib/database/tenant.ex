defmodule Database.Tenant do
  @moduledoc false

  import SqlFmt.Helpers

  alias Ecto.Adapters.SQL
  alias Ecto.Migrator

  @multitenant Application.compile_env!(:passwordless, :multitenant)
  @repo Keyword.fetch!(@multitenant, :repo)
  @tenant_field Keyword.fetch!(@multitenant, :tenant_field)
  @tenant_prefix Keyword.fetch!(@multitenant, :tenant_prefix)
  @tenant_migrations Keyword.fetch!(@multitenant, :tenant_migrations)

  @doc """
  Returns the list of reserved tenants.

  By default, there are some limitations for the name of a tenant depending on
  the database, like "public" or anything that start with "pg_".

  You also can configure your own reserved tenant names if you want with:

      config :triplex, reserved_tenants: ["www", "api", ~r/^db\d+$/]

  Notice that you can use regexes, and they will be applied to the tenant
  names.
  """
  def reserved_tenants do
    [
      nil,
      "oban",
      "public",
      "information_schema",
      "performance_schema",
      "sys",
      "mysql",
      ~r/^pg_/
    ]
  end

  @doc """
  Returns if the given `tenant` is reserved or not.

  The function `to_prefix/1` will be applied to the tenant.
  """
  def reserved_tenant?(tenant) when is_map(tenant) do
    tenant
    |> tenant_field()
    |> reserved_tenant?()
  end

  def reserved_tenant?(tenant) do
    do_reserved_tenant?(tenant) or
      tenant
      |> to_prefix()
      |> do_reserved_tenant?()
  end

  defp do_reserved_tenant?(prefix) do
    Enum.any?(reserved_tenants(), fn i ->
      if is_bitstring(prefix) and Kernel.is_struct(i, Regex) do
        Regex.match?(i, prefix)
      else
        i == prefix
      end
    end)
  end

  @doc """
  Creates the given `tenant` on the given `repo`.

  Returns `{:ok, tenant}` if successful or `{:error, reason}` otherwise.

  Besides creating the database itself, this function also loads their
  structure executing all migrations from inside
  `priv/YOUR_REPO/tenant_migrations` folder. By calling `create_schema/3`
  sending `migrate/2` as the `func` callback.

  See `migrate/2` for more details about the migration running.

  ### Ecto 3 migrations, triplex and transactions

  So on Ecto 3, migrations were changed to run on async tasks. Because of
  that it's not possible anymore to run `Triplex.create/2` inside of a
  transaction anymore.

  But there is a way to achieve the same results using `create_schema/3`
  and `migrate/2`. Here is an example using transaction:

      Repo.transaction(fn ->
        {:ok, _} = Triplex.create("tenant")
        User.insert!(%{name: "Demo user 1"})
        User.insert!(%{name: "Demo user 2"})
      end)

  And here is how you could achieve the same results on success or fail:

      Triplex.create_schema("tenant", Repo, fn(tenant, repo) ->
        Repo.transaction(fn ->
          {:ok, _} = Triplex.migrate(tenant, repo)
          User.insert!(%{name: "Demo user 1"})
          User.insert!(%{name: "Demo user 2"})

          # the `create_schema/3` function must return `{:ok, "tenant"}`
          # if succeeded, and `Repo.transaction` transforms the function results
          # on this tuple
          tenant
        end)
      end)

  So, if the function given to `create_schema/3` returns an error tuple, it will
  rollback the created schema and return that tuple to you. Check out
  `create_schema/3` docs for more details.
  """
  def create(tenant, repo \\ @repo) do
    create_schema(tenant, repo, &migrate(&1, &2))
  end

  @doc """
  Creates the `tenant` schema/database on the given `repo`.

  Returns `{:ok, tenant}` if successful or `{:error, reason}` otherwise.

  After creating it successfully, the given `func` callback is called with
  the `tenant` and the `repo` as arguments. The `func` must return
  `{:ok, any}` if successful or `{:error, reason}` otherwise. In the case
  the `func` fails, this func will rollback the created schema and
  fail with the same `reason`.

  The function `to_prefix/1` will be applied to the `tenant`.
  """
  def create_schema(tenant, repo \\ @repo, func \\ nil) do
    if reserved_tenant?(tenant) do
      {:error, reserved_message(tenant)}
    else
      case SQL.query(repo, "CREATE SCHEMA \"#{to_prefix(tenant)}\"", []) do
        {:ok, _} ->
          case exec_func(func, tenant, repo) do
            {:ok, _} ->
              {:ok, tenant}

            {:error, reason} ->
              drop(tenant, repo)
              {:error, error_message(reason)}
          end

        {:error, reason} ->
          {:error, error_message(reason)}
      end
    end
  end

  defp error_message(msg) do
    if Kernel.is_exception(msg) do
      Exception.message(msg)
    else
      msg
    end
  end

  defp exec_func(nil, tenant, _) do
    {:ok, tenant}
  end

  defp exec_func(func, tenant, repo) when is_function(func) do
    case func.(tenant, repo) do
      {:ok, _} -> {:ok, tenant}
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Drops the given tenant on the given `repo`.

  Returns `{:ok, tenant}` if successful or `{:error, reason}` otherwise.

  The function `to_prefix/1` will be applied to the `tenant`.
  """
  def drop(tenant, repo \\ @repo) do
    if reserved_tenant?(tenant) do
      {:error, reserved_message(tenant)}
    else
      case SQL.query(repo, "DROP SCHEMA \"#{to_prefix(tenant)}\" CASCADE", []) do
        {:ok, _} ->
          {:ok, tenant}

        {:error, exception} ->
          {:error, error_message(exception)}
      end
    end
  end

  def drop_schema(schema, repo \\ @repo) do
    case SQL.query(repo, "DROP SCHEMA \"#{schema}\" CASCADE", []) do
      {:ok, _} ->
        {:ok, schema}

      {:error, exception} ->
        {:error, error_message(exception)}
    end
  end

  @doc """
  Renames the `old_tenant` to the `new_tenant` on the given `repo`.

  Returns `{:ok, new_tenant}` if successful or `{:error, reason}` otherwise.

  The function `to_prefix/1` will be applied to the `old_tenant` and
  `new_tenant`.
  """
  def rename(old_tenant, new_tenant, repo \\ @repo) do
    if reserved_tenant?(new_tenant) do
      {:error, reserved_message(new_tenant)}
    else
      sql = """
      ALTER SCHEMA \"#{to_prefix(old_tenant)}\"
      RENAME TO \"#{to_prefix(new_tenant)}\"
      """

      case SQL.query(repo, sql, []) do
        {:ok, _} ->
          {:ok, new_tenant}

        {:error, message} ->
          {:error, error_message(message)}
      end
    end
  end

  @doc """
  Returns all the tenants on the given `repo`.
  """
  def all(repo \\ @repo) do
    sql = ~SQL"""
    SELECT
      schema_name
    FROM
      information_schema.schemata
    """

    %{rows: result} = SQL.query!(repo, sql, [])

    result
    |> List.flatten()
    |> Enum.reject(&reserved_tenant?/1)
  end

  @doc """
  Returns if the given `tenant` exists or not on the given `repo`.

  The function `to_prefix/1` will be applied to the `tenant`.
  """
  def exists?(tenant, repo \\ @repo) do
    if reserved_tenant?(tenant) do
      false
    else
      sql = ~SQL"""
      SELECT
        COUNT(*)
      FROM
        information_schema.schemata
      WHERE
        schema_name = $1
      """

      %{rows: [[count]]} = SQL.query!(repo, sql, [to_prefix(tenant)])

      count == 1
    end
  end

  @doc """
  Migrates the given `tenant` on your `repo`.

  Returns `{:ok, migrated_versions}` if successful or `{:error, reason}` otherwise.

  The function `to_prefix/1` will be applied to the `tenant`.
  """
  def migrate(tenant, repo \\ @repo) do
    Code.compiler_options(ignore_module_conflict: true)

    try do
      migrated_versions =
        Migrator.run(
          repo,
          migrations_path(repo),
          :up,
          all: true,
          prefix: to_prefix(tenant)
        )

      {:ok, migrated_versions}
    rescue
      exception ->
        {:error, error_message(exception)}
    after
      Code.compiler_options(ignore_module_conflict: false)
    end
  end

  @doc """
  Returns the path for the tenant migrations on your `repo`.
  """
  def migrations_path(repo \\ @repo) do
    repo
    |> Migrator.migrations_path()
    |> Path.join("..")
    |> Path.join(@tenant_migrations)
    |> Path.expand()
  end

  @doc """
  Returns the `tenant` name with the given `prefix`.

  If the `prefix` is omitted, the `tenant_prefix` configuration from
  `Triplex.Config` will be used.

  The `tenant` can be a string, a map or a struct. For a string it will
  be used as the tenant name to concat the prefix. For a map or a struct, it
  will get the `tenant_field/0` from it to concat the prefix.
  """
  def to_prefix(tenant, prefix \\ @tenant_prefix)

  def to_prefix(tenant, prefix) when is_map(tenant) do
    tenant
    |> tenant_field()
    |> to_prefix(prefix)
  end

  def to_prefix(tenant, nil), do: tenant
  def to_prefix(tenant, prefix), do: prefix <> tenant

  @doc """
  Returns the value of the configured tenant field on the given `map`.
  """
  def tenant_field(map) do
    case map
         |> Map.get(@tenant_field)
         |> Passwordless.PrefixedUUID.slug_to_uuid() do
      {:ok, _prefix, uuid} -> String.replace(uuid, "-", "_")
      _ -> raise "The tenant field must be a PrefixedUUID"
    end
  end

  defp reserved_message(tenant) do
    """
    You cannot create the schema because #{inspect(tenant)} is a reserved
    tenant
    """
  end
end
