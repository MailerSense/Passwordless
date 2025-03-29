defmodule Passwordless.OTP do
  @moduledoc """
  A one-time password.
  """

  use Passwordless.Schema, prefix: "otp"

  alias Passwordless.EmailMessage

  @size 6
  @attempts 3

  @derive {Jason.Encoder,
           only: [
             :id,
             :attempts,
             :expires_at,
             :accepted_at
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
    field :accepted_at, :utc_datetime_usec

    belongs_to :email_message, EmailMessage

    timestamps()
  end

  def valid?(%__MODULE__{attempts: attempts}, _candidate) when attempts >= @attempts, do: false

  def valid?(%__MODULE__{code: code, expires_at: expires_at}, candidate) when is_binary(code) and is_binary(candidate) do
    DateTime.after?(expires_at, DateTime.utc_now()) and Plug.Crypto.secure_compare(code, candidate)
  end

  def valid?(%__MODULE__{}, _candidate), do: false

  @fields ~w(
    code
    attempts
    expires_in
    expires_at
    accepted_at
    email_message_id
  )a
  @required_fields @fields -- [:expires_in, :accepted_at, :email_message_id]

  def changeset(%__MODULE__{} = otp, attrs \\ %{}, opts \\ []) do
    otp
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_format(:code, ~r/^\d{#{@size}}$/, message: "should be a 6 digit number")
    |> validate_number(:attempts, greater_than: 0, less_than_or_equal_to: @attempts)
    |> assoc_constraint(:email_message)
    |> unique_constraint(:email_message_id)
    |> unsafe_validate_unique(:email_message_id, Passwordless.Repo)
  end

  def generate_code, do: Util.random_numeric_string(@size)
end
