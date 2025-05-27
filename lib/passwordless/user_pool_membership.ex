defmodule Passwordless.UserPoolMembership do
  @moduledoc """
  An organization membership schema.
  """

  use Passwordless.Schema, prefix: "user_pool_membership"

  alias Passwordless.User
  alias Passwordless.UserPool

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :user_id,
      :user_pool_id,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  schema "user_pool_memberships" do
    belongs_to :user, User
    belongs_to :user_pool, UserPool

    timestamps()
  end

  @fields ~w(
    user_id
    user_pool_id
  )a
  @required_fields @fields

  @doc """
  An organization membership changeset to update a membership.
  """
  def changeset(membership, attrs \\ %{}, _opts \\ []) do
    membership
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :user_pool_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:user_pool)
  end

  @doc """
  A membership changeset to create a new membership.
  """
  def insert_changeset(%User{} = user, %UserPool{} = user_pool) do
    %__MODULE__{}
    |> change(%{user_id: user.id, user_pool_id: user_pool.id})
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :user_pool_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:user_pool)
  end
end
