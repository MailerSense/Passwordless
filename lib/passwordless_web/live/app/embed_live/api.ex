defmodule PasswordlessWeb.App.EmbedLive.API do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.AuthToken
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    auth_token = Repo.preload(app, :auth_token).auth_token
    signed = AuthToken.sign(auth_token)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(auth_token: auth_token, signed: signed)}
  end
end
