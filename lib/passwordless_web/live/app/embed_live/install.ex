defmodule PasswordlessWeb.App.EmbedLive.Install do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.AuthToken
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    case Repo.preload(app, :auth_token) do
      %App{auth_token: %AuthToken{} = auth_token} ->
        keys = [
          %{
            id: "app_id",
            name: gettext("App ID"),
            token: app.id,
            inserted_at: app.inserted_at
          },
          %{
            id: "app_secret",
            name: gettext("Secret Key"),
            token: AuthToken.preview(auth_token),
            inserted_at: auth_token.inserted_at
          }
        ]

        {:ok,
         socket
         |> assign(assigns)
         |> assign(
           keys: keys,
           reveal_secret?: false,
           secret: AuthToken.encode(auth_token)
         )}

      _ ->
        keys = [
          %{
            id: "app_id",
            name: gettext("App ID"),
            token: app.id,
            inserted_at: app.inserted_at
          }
        ]

        {:ok,
         socket
         |> assign(assigns)
         |> assign(keys: keys, reveal_secret?: false, secret: nil)}
    end
  end

  @impl true
  def handle_event("toggle_reveal_secret", _params, socket) do
    {:noreply, update(socket, :reveal_secret?, &Kernel.not/1)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end
end
