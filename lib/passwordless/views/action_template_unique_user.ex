defmodule Passwordless.Views.ActionTemplateUniqueUser do
  @moduledoc """
  Materialized view for getting an approximate unique user count for an action.
  """

  use Ecto.Schema

  import Ecto.Query

  alias Database.Tenant
  alias Passwordless.App

  @primary_key {:action_template_id, Database.PrefixedUUID, prefix: "action_template", autogenerate: true}
  @timestamps_opts false
  @foreign_key_type Database.PrefixedUUID

  schema "action_template_unique_users" do
    field :name, :string, virtual: true
    field :users, :integer
  end

  @doc """
  Get all entities by app.
  """
  def get_by_app(query, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
  end
end
