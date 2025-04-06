defmodule Passwordless.Repo.Migrations.AddOban do
  use Ecto.Migration

  def up do
    Oban.Migration.up(prefix: "oban")
  end

  def down do
    Oban.Migration.down(prefix: "oban")
  end
end
