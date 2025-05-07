defmodule Passwordless.Challenges.RecoveryCodes do
  @moduledoc """
  TOTP flow.
  """

  @behaviour Passwordless.Challenge

  alias Database.Tenant
  alias Passwordless.Action
  alias Passwordless.App
  alias Passwordless.Challenge
  alias Passwordless.RecoveryCodes
  alias Passwordless.Repo
  alias Passwordless.User

  @challenge :recovery_codes

  @impl true
  def handle(
        %App{} = app,
        %User{} = user,
        %Action{challenge: %Challenge{kind: @challenge, state: :started} = challenge} = action,
        event: "use_recovery_code",
        attrs: %{code: code}
      )
      when is_binary(code) do
    case Repo.preload(user, :recovery_codes) do
      %User{recovery_codes: %RecoveryCodes{} = recovery_codes} ->
        case RecoveryCodes.validate_code(recovery_codes, code) do
          %Ecto.Changeset{} = changeset ->
            with {:ok, _codes} <- Repo.update(changeset),
                 {:ok, _challenge} <- update_challenge_state(app, challenge, :recovery_code_accepted),
                 do: {:ok, action}

          _ ->
            {:error, :invalid_recovery_code}
        end

      _ ->
        {:error, :no_recovery_codes_enrolled}
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
