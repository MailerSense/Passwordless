defmodule Passwordless.Challenges.TOTP do
  @moduledoc """
  TOTP flow.
  """

  @behaviour Passwordless.Challenge

  alias Database.Tenant
  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Challenge
  alias Passwordless.Repo
  alias Passwordless.TOTP

  @challenge :totp

  @impl true
  def handle(
        %App{} = app,
        %Actor{} = actor,
        %Action{challenge: %Challenge{kind: @challenge, state: :started} = challenge} = action,
        event: "validate_totp",
        attrs: %{code: code}
      )
      when is_binary(code) do
    case Repo.preload(actor, :totps) do
      %Actor{totps: [_ | _] = totps} ->
        case Enum.find(totps, &TOTP.valid_totp?(&1, code)) do
          %TOTP{} = _totp ->
            with {:ok, _challenge} <- update_challenge_state(app, challenge, :totp_validated),
                 do: {:ok, action}

          _ ->
            {:error, :invalid_totp_code}
        end

      _ ->
        {:error, :no_totp_enrolled}
    end
  end

  # Private

  defp update_action_state(%App{} = app, %Action{} = action, state) do
    opts = [prefix: Tenant.to_prefix(app)]

    action
    |> Action.state_changeset(%{state: state})
    |> Repo.update(opts)
  end

  defp update_challenge_state(%App{} = app, %Challenge{} = challenge, state) do
    opts = [prefix: Tenant.to_prefix(app)]

    challenge
    |> Challenge.state_changeset(%{state: state})
    |> Repo.update(opts)
  end
end
