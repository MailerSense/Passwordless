defmodule Passwordless.Repo.Migrations.RemoveOldObanJobs do
  use Ecto.Migration

  def change do
    drop_if_exists table(:oban_jobs_old), prefix: "oban"
  end
end
