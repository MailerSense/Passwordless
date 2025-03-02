defmodule PasswordlessWeb.App.EmbedLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @methods [
    secrets: PasswordlessWeb.App.EmbedLive.Secrets,
    login_page: PasswordlessWeb.App.EmbedLive.Secrets,
    auth_guard: PasswordlessWeb.App.EmbedLive.Secrets
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action)
     |> assign(module: Keyword.fetch!(@methods, socket.assigns.live_action))}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, _action) do
    assign(socket,
      page_title: gettext("Embed & API"),
      page_subtitle: gettext("Manage your integrations")
    )
  end
end
