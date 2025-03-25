defmodule Passwordless.Flows.Email do
  @moduledoc """
  Email OTP flow.
  """

  use StateMachine
  use Ecto.Schema

  import Ecto.Changeset

  @states ~w(started otp_sent otp_valid otp_invalid otp_exhausted)a
  @otp_size 6
  @max_attempts 3

  @primary_key false
  embedded_schema do
    field :code, Passwordless.EncryptedBinary
    field :state, Ecto.Enum, values: @states, default: :started
    field :attempts, :integer, default: 0
  end

  @fields ~w(code state attempts)a
  @required_fields @fields

  def changeset(%__MODULE__{} = schema, attrs \\ %{}) do
    schema
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_format(:code, ~r/^\d{#{@otp_size}}$/, message: "should be a 6 digit number")
    |> validate_number(:attempts, greater_than: 0, less_than_or_equal_to: @max_attempts)
  end

  defmachine field: :state do
    state(:started)
    state(:otp_sent)
    state(:otp_valid, success: true)
    state(:otp_invalid)
    state(:otp_exhausted, fail: true)

    event :send_otp do
      transition(
        from: :started,
        to: :otp_sent,
        before: &__MODULE__.send_otp/1
      )

      transition(
        from: :otp_sent,
        to: :otp_sent,
        before: &__MODULE__.resend_otp/1
      )
    end

    event :validate_otp do
      transition(
        from: [:otp_sent, :otp_invalid],
        to: :otp_valid,
        if: &__MODULE__.otp_valid?/2
      )

      transition(
        from: :otp_sent,
        to: :otp_invalid,
        unless: &__MODULE__.otp_valid?/2,
        before: &__MODULE__.bump_attempt/1
      )

      transition(
        from: :otp_invalid,
        to: :otp_exhausted,
        if: &__MODULE__.otp_exhausted?/1
      )
    end
  end

  def send_otp(%__MODULE__{} = mod) do
    mod
    |> changeset(%{code: Util.random_numeric_string(@otp_size)})
    |> apply_action(:new)
  end

  def resend_otp(%__MODULE__{} = mod) do
    mod
    |> changeset(%{code: Util.random_numeric_string(@otp_size)})
    |> apply_action(:new)
  end

  @doc """
  Verify if the OTP code is valid.
  """
  def otp_valid?(%__MODULE__{code: code}, %Context{payload: %{code: candidate}})
      when is_binary(code) and byte_size(code) == 6 and is_binary(candidate) and byte_size(candidate) == 6,
      do: Plug.Crypto.secure_compare(code, candidate)

  def otp_valid?(%__MODULE__{}, %Context{}), do: false

  @doc """
  Check if the OTP attempts are exhausted.
  """
  def otp_exhausted?(%__MODULE__{attempts: attempts}) when attempts >= @max_attempts, do: true
  def otp_exhausted?(%__MODULE__{}), do: false

  @doc """
  Increment the OTP attempts.
  """
  def bump_attempt(%__MODULE__{attempts: attempts} = mod) do
    mod
    |> changeset(%{attempts: attempts + 1})
    |> apply_action(:validate)
  end
end
