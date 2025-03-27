defmodule Passwordless.OTP do
  @moduledoc """
  A one-time password.
  """

  use Passwordless.Schema, prefix: "otp"

  @size 6
  @attempts 3

  @derive {Jason.Encoder,
           only: [
             :id,
             :code,
             :attempts,
             :expires_at
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "otps" do
    field :code, Passwordless.EncryptedBinary
    field :attempts, :integer, default: 0
    field :expires_at, :utc_datetime_usec
    field :expires_in, :integer, virtual: true

    belongs_to :action, Action

    timestamps()
  end

  @fields ~w(code attempts expires_in expires_at)a
  @required_fields @fields -- [:expires_in]

  def changeset(%__MODULE__{} = otp, attrs \\ %{}, opts \\ []) do
    otp
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_format(:code, ~r/^\d{#{@size}}$/, message: "should be a 6 digit number")
    |> validate_number(:attempts, greater_than: 0, less_than_or_equal_to: @attempts)
    |> assoc_constraint(:action)
    |> unique_constraint(:action_id)
    |> unsafe_validate_unique(:action_id, Passwordless.Repo)
  end

  def generate_code, do: Util.random_numeric_string(@size)
end
