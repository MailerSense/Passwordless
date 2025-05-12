defmodule Passwordless.TopAction do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  alias Passwordless.ActionTemplate

  @primary_key {:template_id, Uniq.UUID, version: 7, autogenerate: true}
  @timestamps_opts false
  @foreign_key_type :binary_id
  schema "top_action_templates" do
    field :name, :string, virtual: true
    field :action_count, :integer
    field :state_allow_count, :integer
    field :state_timeout_count, :integer
    field :state_block_count, :integer
  end

  @doc """
  Get by schedule IDs.
  """
  def join_with_templates(query \\ __MODULE__, opts \\ []) do
    from q in query,
      prefix: ^Keyword.get(opts, :prefix, :public),
      join: t in ActionTemplate,
      prefix: ^Keyword.get(opts, :prefix, :public),
      on: t.id == q.template_id,
      select_merge: %{name: t.name},
      order_by: [desc: q.action_count]
  end
end
