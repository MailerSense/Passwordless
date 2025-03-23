defmodule Passwordless.Flows.EmailOTP do
  @moduledoc """
  Email OTP flow.
  """

  use StateMachine
  use TypedStruct

  alias StateMachine.Context

  @started :started
  @finished :otp_valid
  @max_attempts 3

  typedstruct do
    field :code, binary(), enforce: true
    field :email, binary(), enforce: true
    field :state, atom(), default: @started
    field :attempts, non_neg_integer(), default: 0
  end

  defmachine field: :state do
    state(:started)
    state(:otp_sent)
    state(:otp_valid)
    state(:otp_invalid)
    state(:otp_exhausted)

    event :send_otp do
      transition(
        from: [:started, :otp_sent],
        to: :otp_sent,
        before: &__MODULE__.send_otp/1
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
        before: &__MODULE__.bump_attempt?/1,
        unless: &__MODULE__.otp_valid?/2
      )

      transition(
        from: :otp_invalid,
        to: :otp_exhausted,
        if: &__MODULE__.otp_exhausted?/1
      )
    end
  end

  def valid?(%__MODULE__{state: @finished}), do: true
  def valid?(%__MODULE__{}), do: false

  def send_otp(%__MODULE__{} = mod) do
    # To-Do: actually send the OTP
    {:ok, mod}
  end

  def otp_valid?(%__MODULE__{code: code, attempts: attempts}, %Context{payload: %{code: candidate}})
      when is_binary(code) and byte_size(code) == 6 and is_binary(candidate) and byte_size(candidate) == 6 and
             attempts < @max_attempts,
      do: Plug.Crypto.secure_compare(code, candidate)

  def otp_valid?(%__MODULE__{}, %Context{}), do: false

  def otp_exhausted?(%__MODULE__{attempts: attempts}) when attempts >= @max_attempts, do: true
  def otp_exhausted?(%__MODULE__{}), do: false

  def bump_attempt?(%__MODULE__{attempts: attempts} = mod), do: {:ok, %__MODULE__{mod | attempts: attempts + 1}}
end
