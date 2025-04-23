defmodule Passwordless.Challenges.MagicLink do
  @moduledoc false

  @behaviour Passwordless.Challenge

  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Authenticators
  alias Passwordless.Challenge
  alias Passwordless.Email

  @challenge :magic_link

  @impl true
  def handle(
        %App{} = app,
        %Actor{} = actor,
        %Action{challenge: %Challenge{kind: @challenge, state: state} = challenge} = action,
        event: :send_magic_link,
        attrs: %{email: %Email{} = email, authenticator: %Authenticators.MagicLink{} = authenticator}
      ) do
    {:ok, action}
  end
end
