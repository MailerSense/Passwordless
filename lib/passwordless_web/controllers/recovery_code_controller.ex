defmodule PasswordlessWeb.RecoveryCodeController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Accounts.User
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.RecoveryCodes
  alias Passwordless.Repo

  def download(conn, %{"actor_id" => actor_id}, %User{current_app: %App{} = app}) do
    actor = app |> Passwordless.get_actor!(actor_id) |> Repo.preload(:recovery_codes)

    case actor do
      %Actor{recovery_codes: %RecoveryCodes{codes: [_ | _] = codes}} ->
        data =
          codes
          |> Enum.chunk_every(2)
          |> Enum.map_join("\n", fn [a, b] -> "#{a.code}\t#{b.code}" end)

        data = "Recovery codes for #{Actor.handle(actor)}:\n\n#{data}"

        send_download(conn, {:binary, data},
          filename: "Recovery codes - #{Actor.handle(actor)}.txt",
          content_type: "text/plain"
        )

      _ ->
        {:error, :no_recovery_codes}
    end
  end
end
