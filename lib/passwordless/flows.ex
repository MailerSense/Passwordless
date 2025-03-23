defmodule Passwordless.Flows do
  @moduledoc false

  alias Passwordless.Flows

  @flows [
    email_otp: Flows.EmailOTP
  ]

  def all_flows do
    Keyword.keys(@flows)
  end

  def all_events do
    @flows
    |> Keyword.values()
    |> Enum.flat_map(& &1.all_events())
    |> Enum.uniq()
  end

  def all_states do
    @flows
    |> Keyword.values()
    |> Enum.flat_map(& &1.all_states())
    |> Enum.uniq()
  end
end
