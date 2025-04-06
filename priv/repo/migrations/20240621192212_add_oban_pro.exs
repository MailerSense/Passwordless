defmodule Passwordless.Repo.Migrations.AddObanPro do
  use Ecto.Migration

  def up do
    Oban.Pro.Migration.up(prefix: "oban")
  end

  def down do
    Oban.Pro.Migration.down(prefix: "oban")
  end
end
