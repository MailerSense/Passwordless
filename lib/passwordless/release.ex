defmodule Passwordless.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """

  require Logger

  @app :passwordless

  def migrate_lambda(request, context) when is_map(request) and is_map(context) do
    Logger.info("""
    Hello Lambda!
    Got lambda reqeust #{inspect(request)}
    Got lambda context #{inspect(context)}
    """)

    migrate()

    %{
      statusCode: 200,
      body: "Migration Complete"
    }
  end

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(
          repo,
          fn repo ->
            Ecto.Adapters.Postgres.execute_ddl(repo, "drop schema public cascade;", [])
            Ecto.Adapters.Postgres.execute_ddl(repo, "create schema public;", [])

            Ecto.Migrator.run(repo, :up, all: true)

            :passwordless
            |> :code.priv_dir()
            |> Path.join("repo/seeds.prod.exs")
            |> Code.eval_file()
          end,
          pool_size: 10
        )
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  # Private

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
    {:ok, _} = Application.ensure_all_started(@app)
  end
end
