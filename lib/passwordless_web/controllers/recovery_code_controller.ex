defmodule PasswordlessWeb.RecoveryCodeController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Accounts.User, as: AccountsUser
  alias Passwordless.App
  alias Passwordless.RecoveryCodes
  alias Passwordless.Repo
  alias Passwordless.User

  def download(conn, %{"user_id" => user_id}, %AccountsUser{current_app: %App{} = app}) do
    case app |> Passwordless.get_user!(user_id) |> Repo.preload(:recovery_codes) do
      %User{recovery_codes: %RecoveryCodes{codes: [_ | _] = codes}} = user ->
        data =
          codes
          |> Enum.chunk_every(2)
          |> Enum.map_join("\n", fn [a, b] -> "#{a.code}\t#{b.code}" end)

        data = "Recovery codes for #{User.handle(user)}:\n\n#{data}"

        send_download(conn, {:binary, data},
          filename: "Recovery codes - #{User.handle(user)}.txt",
          content_type: "text/plain"
        )

      _ ->
        {:error, :no_recovery_codes}
    end
  end
end
