defmodule Passwordless.Enrollment do
  @moduledoc """
  An enrollment.
  """

  use Passwordless.Schema, prefix: "enrlmnt"

  alias Passwordless.TOTP
  alias Passwordless.User

  @states ~w(started)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :totp,
      :user,
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
    belongs_to :user, User

    timestamps()
  end

  @fields ~w(
    state
    totp_id
    user_id
  )a
  @required_fields @fields -- [:totp_id]

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = enrollment, attrs \\ %{}, opts \\ []) do
    enrollment
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:totp)
    |> assoc_constraint(:user)
  end
end
