defmodule PasswordlessWeb.App.EmbedLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    socket =
      assign(socket,
        integrations: []
      )

    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/embed")}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Embed & API"),
      page_subtitle: gettext("Manage your integrations")
    )
  end
end
