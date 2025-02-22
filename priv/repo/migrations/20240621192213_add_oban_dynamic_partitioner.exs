defmodule Passwordless.Repo.Migrations.AddObanDynamicPartitioner do
  use Ecto.Migration

  defdelegate change, to: Oban.Pro.Migrations.DynamicPartitioner
end
