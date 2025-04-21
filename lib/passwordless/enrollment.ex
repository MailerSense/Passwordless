defmodule Passwordless.Enrollment do
  @moduledoc """
  An enrollment.
  """

  use Passwordless.Schema, prefix: "enrlmnt"

  alias Passwordless.Actor
  alias Passwordless.TOTP

  @states ~w(started)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :totp,
      :actor,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "enrollments" do
    field :state, Ecto.Enum, values: @states

    belongs_to :totp, TOTP
    belongs_to :actor, Actor

    timestamps()
  end

  @fields ~w(
    state
    totp_id
    actor_id
  )a
  @required_fields @fields -- [:totp_id]

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}, opts \\ []) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:totp)
    |> assoc_constraint(:actor)
  end
end
