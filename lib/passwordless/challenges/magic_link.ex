defmodule Passwordless.Challenges.MagicLink do
  @moduledoc false

  @behaviour Passwordless.Challenge

  alias Passwordless.Action
  alias Passwordless.App
  alias Passwordless.Authenticators
  alias Passwordless.Cache
  alias Passwordless.Challenge
  alias Passwordless.Email
  alias Passwordless.User

  @challenge :magic_link

  @impl true
  def handle(
        %App{} = app,
        %User{} = user,
        %Action{challenge: %Challenge{kind: @challenge, state: state} = challenge} = action,
        event: :send_magic_link,
        attrs: %{email: %Email{} = email, authenticator: %Authenticators.MagicLink{} = authenticator}
      ) do
    {:ok, action}
  end

  # Private

  defp rate_limit_reached?(%App{} = app, %Email{} = email) do
    if Cache.exists?(rate_limit_key(app, email)),
      do: {:error, :rate_limit_reached},
      else: :ok
  end

  defp apply_rate_limit(%App{} = app, %Authenticators.MagicLink{} = authenticator, %Email{} = email) do
    Cache.put(rate_limit_key(app, email), true, ttl: :timer.seconds(authenticator.resend))
    :ok
  end

  defp rate_limit_key(%App{id: id}, %Email{address: address}), do: "email_otp:#{id}:#{address}"
end
