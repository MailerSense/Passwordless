defmodule Passwordless.Repo.Migrations.AddObanProducers do
  use Ecto.Migration

  def change do
    Oban.Pro.Migrations.Producers.change(prefix: "oban")
  end
end
