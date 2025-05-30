defmodule Passwordless.Views.ActionTemplateMonthlyStats do
  @moduledoc """
  Materialized view for month-to-month comparizon of action performance.
  """

  use Ecto.Schema

  import Ecto.Query

  alias Database.Tenant
  alias Passwordless.ActionTemplate
  alias Passwordless.App

  @primary_key {:action_template_id, Database.PrefixedUUID, prefix: "action_template", autogenerate: true}
  @timestamps_opts false
  @foreign_key_type Database.PrefixedUUID

  schema "action_template_monthly_stats" do
    field :attempts, :integer
    field :allows, :integer
    field :timeouts, :integer
    field :blocks, :integer
    field :date, :date, virtual: true
    field :date_year, :integer
    field :date_month, :integer
  end

  @doc """
  Get all entities by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
  end

  @doc """
  Get all entities by action template.
  """
  def get_by_action_template(query \\ __MODULE__, %ActionTemplate{} = action_template) do
    from q in query, where: q.action_template_id == ^action_template.id
  end
end
