defmodule PasswordlessWeb.Org.AuthTokenLive.RevealComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  @impl true
  def update(assigns, socket) do
    signed_key = Cache.get(assigns.auth_token.id)
    Cache.delete(assigns.auth_token.id)
    {:ok, assign(socket, signed_key: signed_key)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end
end
