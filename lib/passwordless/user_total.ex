defmodule Passwordless.UserTotal do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  alias Database.Tenant
  alias Passwordless.App

  @primary_key false
  @timestamps_opts false

  schema "user_total" do
    field :users, :integer
  end

  @doc """
  Get all entities by app.
  """
  def get_by_app(query, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
  end
end
