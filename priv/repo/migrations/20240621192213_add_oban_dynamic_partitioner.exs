defmodule Passwordless.Repo.Migrations.AddObanDynamicPartitioner do
  use Ecto.Migration

  def change do
    Oban.Pro.Migrations.DynamicPartitioner.change(prefix: "oban")
  end
end
