defmodule Passwordless.Repo.Migrations.AddObanDynamicCron do
  use Ecto.Migration

  defdelegate change, to: Oban.Pro.Migrations.DynamicCron
end
