defmodule Passwordless.Accounts.OTP do
  @moduledoc false

  use Passwordless.Schema, prefix: "accotp"

  alias Passwordless.Accounts.User

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
  schema "user_otps" do
    field :code, Passwordless.EncryptedBinary
    field :attempts, :integer, default: 0
    field :expires_at, :utc_datetime_usec
    field :accepted_at, :utc_datetime_usec

    belongs_to :user, User

    timestamps()
  end

  def size, do: @size

  def valid?(%__MODULE__{attempts: attempts}, _candidate) when attempts >= @attempts, do: false

  def valid?(%__MODULE__{code: code, expires_at: expires_at}, candidate) when is_binary(code) and is_binary(candidate) do
    DateTime.after?(expires_at, DateTime.utc_now()) and
      Plug.Crypto.secure_compare(code, candidate)
  end

  def valid?(%__MODULE__{}, _candidate), do: false

  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.before?(expires_at, DateTime.utc_now())
  end

  def validate(%__MODULE__{} = otp, candidate) do
    cond do
      DateTime.before?(otp.expires_at, DateTime.utc_now()) ->
        {:error, :expired}

      otp.attempts >= @attempts ->
        {:error, :too_many_incorrect_attempts}

      not Plug.Crypto.secure_compare(otp.code, candidate) ->
        {:error, :incorrect_code}

      true ->
        {:ok, otp}
    end
  end

  @fields ~w(
    code
    attempts
    expires_at
    accepted_at
    user_id
  )a
  @required_fields @fields -- [:accepted_at]

  def changeset(%__MODULE__{} = otp, attrs \\ %{}) do
    otp
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_length(:code, is: @size)
    |> validate_format(:code, ~r/^\d{#{@size}}$/, message: "should be a 6 digit number")
    |> validate_number(:attempts, greater_than: 0, less_than_or_equal_to: @attempts)
    |> assoc_constraint(:user)
    |> unique_constraint(:user_id)
    |> unsafe_validate_unique(:user_id, Passwordless.Repo)
  end

  def generate_code, do: Util.random_numeric_string(@size)
end
