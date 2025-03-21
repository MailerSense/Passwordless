defmodule Passwordless.Repo.Migrations.AddObanDynamicCron do
  use Ecto.Migration

  def change do
    Oban.Pro.Migrations.DynamicCron.change(prefix: "oban")
  end
end
