defmodule Passwordless.Repo.TenantMigrations.CreateViews do
  use Ecto.Migration

  import SqlFmt.Helpers

  def up do
    execute """
    CREATE MATERIALIZED VIEW #{prefix()}.top_action_templates AS
    SELECT
      at.id AS action_template_id,
      COUNT(a.id) AS action_count,
      COUNT(a.id) FILTER(
        WHERE
          a.state = 'allow'
      ) AS state_allow_count,
      COUNT(a.id) FILTER(
        WHERE
          a.state = 'timeout'
      ) AS state_timeout_count,
      COUNT(a.id) FILTER(
        WHERE
          a.state = 'block'
      ) AS state_block_count
    FROM
      #{prefix()}.action_templates at
      JOIN #{prefix()}.actions a ON a.action_template_id = at.id
    WHERE
      at.deleted_at IS NULL AND a.state in ('allow', 'timeout', 'block')
    GROUP BY
      at.id
    ORDER BY
      COUNT(a.id) DESC
    LIMIT
      3;
    """

    execute """
    CREATE UNIQUE INDEX ON #{prefix()}.top_action_templates (action_template_id);
    """
  end

  def down do
    execute ~SQL"DROP VIEW top_action_templates;"
  end
end
