defmodule Passwordless.Identity do
  @moduledoc """
  An identity.
  """

  use Passwordless.Schema

  alias Database.ChangesetExt
  alias Passwordless.Actor

  @derive {Jason.Encoder,
           only: [
             :id,
             :system,
             :user_id
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "identities" do
    field :system, :string
    field :user_id, :string

    belongs_to :actor, Actor, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    system
    user_id
    actor_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}, opts \\ []) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:actor_id, :system, :user_id], error_key: :user_id)
    |> unsafe_validate_unique([:actor_id, :system, :user_id], Passwordless.Repo,
      error_key: :user_id,
      prefix: Keyword.get(opts, :prefix)
    )
    |> assoc_constraint(:actor)
  end
end
