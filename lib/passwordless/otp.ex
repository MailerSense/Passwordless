defmodule Passwordless.OTP do
  @moduledoc """
  A one-time password.
  """

  use Passwordless.Schema, prefix: "otp"

  alias Passwordless.EmailMessage

  @size 6
  @attempts 3

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :attempts,
      :expires_at,
      :accepted_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "otps" do
    field :code, Passwordless.EncryptedBinary
    field :attempts, :integer, default: 0
    field :expires_at, :utc_datetime_usec
    field :accepted_at, :utc_datetime_usec

    belongs_to :email_message, EmailMessage

    timestamps()
  end

  def size, do: @size

  @doc """
  Checks if the OTP is valid.
  """
  def valid?(%__MODULE__{code: code, attempts: attempts}, candidate)
      when attempts < @attempts and is_binary(code) and is_binary(candidate) and byte_size(candidate) == @size,
      do: Plug.Crypto.secure_compare(code, candidate)

  def valid?(%__MODULE__{}, _candidate), do: false

  @doc """
  Checks if the OTP is expired.
  """
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.before?(expires_at, DateTime.utc_now())
  end

  @doc """
  Generates a new OTP code.
  """
  def generate_code, do: Util.random_numeric_string(@size)

  @fields ~w(
    code
    attempts
    expires_at
    accepted_at
    email_message_id
  )a
  @required_fields @fields -- [:accepted_at, :email_message_id]

  def changeset(%__MODULE__{} = otp, attrs \\ %{}, opts \\ []) do
    otp
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_length(:code, is: @size)
    |> validate_format(:code, ~r/^\d{#{@size}}$/, message: "should be a 6 digit number")
    |> validate_number(:attempts, greater_than: 0, less_than_or_equal_to: @attempts)
    |> assoc_constraint(:email_message)
    |> unique_constraint(:email_message_id)
    |> unsafe_validate_unique(:email_message_id, Passwordless.Repo, opts)
  end
end
