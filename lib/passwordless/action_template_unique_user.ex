defmodule Passwordless.ActionTemplateUniqueUser do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  alias Database.Tenant
  alias Passwordless.ActionTemplate
  alias Passwordless.App

  @primary_key {:action_template_id, Database.PrefixedUUID, prefix: "action", autogenerate: true}
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

  def get_by_template(query \\ __MODULE__, %ActionTemplate{id: action_template_id}) do
    from q in query, where: q.action_template_id == ^action_template_id
  end

  @doc """
  Get by schedule IDs.
  """
  def join_with_templates(query \\ __MODULE__, opts \\ []) do
    from q in query,
      join: t in ActionTemplate,
      prefix: ^Keyword.get(opts, :prefix, :public),
      on: t.id == q.action_template_id,
      select_merge: %{name: t.name},
      order_by: [desc: q.users]
  end
end
