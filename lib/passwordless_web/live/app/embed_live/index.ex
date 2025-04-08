defmodule PasswordlessWeb.App.EmbedLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @tabs [
    install: PasswordlessWeb.App.EmbedLive.Install,
    api: PasswordlessWeb.App.EmbedLive.API,
    ui: PasswordlessWeb.App.EmbedLive.UI
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
     |> assign(module: Keyword.fetch!(@tabs, socket.assigns.live_action))}
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
