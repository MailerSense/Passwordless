defmodule Passwordless.Repo.TenantMigrations.CreateViews do
  use Ecto.Migration

  import SqlFmt.Helpers

  def up do
    execute ~SQL"""
            CREATE MATERIALIZED VIEW prefix.action_template_unique_users AS
            SELECT
              at.id AS action_template_id,
              COUNT(DISTINCT a.user_id) AS users
            FROM
              prefix.action_templates at
              JOIN prefix.actions a ON a.action_template_id = at.id
            WHERE
              at.deleted_at IS NULL
              AND a.state IN ('allow', 'timeout', 'block')
            GROUP BY
              at.id;
            """
            |> String.replace("prefix", prefix())

    execute ~SQL"""
            CREATE MATERIALIZED VIEW prefix.user_total AS
            SELECT
              COUNT(*) AS users
            FROM
              prefix.users
            WHERE
              deleted_at IS NULL;
            """
            |> String.replace("prefix", prefix())

    execute ~SQL"""
            CREATE UNIQUE INDEX ON prefix.action_template_unique_users (action_template_id);
            """
            |> String.replace("prefix", prefix())
  end

  def down do
    execute ~SQL"DROP VIEW prefix.action_template_unique_users;"
            |> String.replace("prefix", prefix())

    execute ~SQL"DROP VIEW prefix.user_total;" |> String.replace("prefix", prefix())
  end
end
