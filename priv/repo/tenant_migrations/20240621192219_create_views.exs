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
            CREATE UNIQUE INDEX ON prefix.action_template_unique_users (action_template_id);
            """
            |> String.replace("prefix", prefix())

    execute ~SQL"""
            CREATE MATERIALIZED VIEW prefix.action_template_monthly_stats AS
            SELECT
              a.action_template_id,
              COUNT(a.id) AS attempts,
              COUNT(*) FILTER (
                WHERE
                  a.state = 'allow'
              ) AS allows,
              COUNT(*) FILTER (
                WHERE
                  a.state = 'block'
              ) AS blocks,
              DATE_PART('year', a.inserted_at :: date) :: int AS date_year,
              DATE_PART('month', a.inserted_at :: date) :: int AS date_month
            FROM
              prefix.actions a
            WHERE
              a.inserted_at >= date_trunc('month', CURRENT_DATE) - INTERVAL '1 month'
            GROUP BY
              a.action_template_id,
              DATE_PART('year', a.inserted_at :: date) :: int,
              DATE_PART('month', a.inserted_at :: date) :: int;
            """
            |> String.replace("prefix", prefix())

    execute ~SQL"""
            CREATE UNIQUE INDEX ON prefix.action_template_monthly_stats (action_template_id, date_year, date_month);
            """
            |> String.replace("prefix", prefix())
  end

  def down do
    execute ~SQL"DROP VIEW prefix.action_template_unique_users;"
            |> String.replace("prefix", prefix())
  end
end
