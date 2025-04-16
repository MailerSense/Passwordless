defmodule PasswordlessWeb.App.EmbedLive.Install do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    auth_token = Repo.preload(app, :auth_token).auth_token

    keys = [
      %{
        id: "app_id",
        name: gettext("App ID"),
        token: app.id,
        inserted_at: app.inserted_at
      },
      %{
        id: "app_secret",
        name: gettext("App Secret"),
        token: "******",
        inserted_at: auth_token.inserted_at
      }
    ]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(keys: keys, auth_token: auth_token)}
  end
end
