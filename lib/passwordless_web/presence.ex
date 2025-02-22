defmodule PasswordlessWeb.Presence do
  @moduledoc false
  use Phoenix.Presence, otp_app: :passwordless, pubsub_server: Passwordless.PubSub

  alias Passwordless.Accounts.User

  def online_user?(%User{} = user) do
    online = not ("users" |> get_by_key(user.id) |> Enum.empty?())
    %{user | is_online: online}
  end

  def online_users(users) when is_list(users) do
    Enum.map(users, &online_user?/1)
  end
end
