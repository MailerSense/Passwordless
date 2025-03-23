defmodule Passwordless.Flows.EmailOTP do
  @moduledoc """
  Email OTP flow.
  """

  use StateMachine
  use TypedStruct

  @max_attempts 3

  typedstruct do
    field :id, UUIDv7.t(), enforce: true
    field :code, binary(), enforce: true
    field :email, map(), enforce: true
    field :state, atom(), default: :started
    field :message, map()
    field :attempts, non_neg_integer(), default: 0
  end

  defmodule ValidateOTP do
    @moduledoc """
    Validate OTP code.
    """
    use TypedStruct

    typedstruct do
      use TypedStruct.Schema

      field :code, binary(), enforce: true
    end
  end

  defmachine field: :state do
    state(:started)
    state(:otp_sent)
    state(:otp_valid, success: true)
    state(:otp_invalid)
    state(:otp_exhausted, fail: true)

    event :send_otp do
      transition(
        from: [:started, :otp_sent],
        to: :otp_sent,
        before: &__MODULE__.send_otp/1,
        after: &__MODULE__.log_otp_sent/1
      )
    end

    event :validate_otp do
      transition(
        schema: __MODULE__.ValidateOTP,
        from: [:otp_sent, :otp_invalid],
        to: :otp_valid,
        if: &__MODULE__.otp_valid?/2,
        after: &__MODULE__.log_otp_validated/1
      )

      transition(
        from: :otp_sent,
        to: :otp_invalid,
        before: &__MODULE__.bump_attempt/1,
        unless: &__MODULE__.otp_valid?/2,
        after: &__MODULE__.log_otp_invalid/1
      )

      transition(
        from: :otp_invalid,
        to: :otp_exhausted,
        if: &__MODULE__.otp_exhausted?/1,
        after: &__MODULE__.log_otp_exhausted/1
      )
    end
  end

  def send_otp(%__MODULE__{} = mod) do
    # To-Do: actually send the OTP
    {:ok, mod}
  end

  @doc """
  Verify if the OTP code is valid.
  """
  def otp_valid?(%__MODULE__{code: code, attempts: attempts}, %Context{payload: %__MODULE__.ValidateOTP{code: candidate}})
      when is_binary(code) and byte_size(code) == 6 and is_binary(candidate) and byte_size(candidate) == 6 and
             attempts < @max_attempts,
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
  def bump_attempt(%__MODULE__{attempts: attempts} = mod), do: {:ok, %__MODULE__{mod | attempts: attempts + 1}}

  def log_otp_sent(%__MODULE__{} = mod) do
    {:ok, mod}
  end

  def log_otp_validated(%__MODULE__{} = mod) do
    {:ok, mod}
  end

  def log_otp_invalid(%__MODULE__{} = mod) do
    {:ok, mod}
  end

  def log_otp_exhausted(%__MODULE__{} = mod) do
    {:ok, mod}
  end
end
