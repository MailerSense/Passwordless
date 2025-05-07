defmodule Passwordless.ActionTemplate do
  @moduledoc false

  use Passwordless.Schema, prefix: "action"

  import Ecto.Query

  alias Passwordless.App

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "action_templates" do
    belongs_to :app, App

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, where: q.app_id == ^app.id
  end

  @fields ~w(
    app_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action_template, attrs \\ %{}, opts \\ []) do
    action_template
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:app)
  end
end
