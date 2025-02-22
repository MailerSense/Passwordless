defmodule PasswordlessWeb.Admin.Filters.SoftDelete do
  @moduledoc false

  use Backpex.Filters.Boolean

  @impl Backpex.Filter
  def label, do: "Deleted?"

  @impl Backpex.Filters.Boolean
  def options do
    [
      %{
        label: "Deleted",
        key: "yes",
        predicate: dynamic([x], not is_nil(x.deleted_at))
      },
      %{
        label: "Not deleted",
        key: "no",
        predicate: dynamic([x], is_nil(x.deleted_at))
      }
    ]
  end
end
