defmodule PasswordlessWeb.App.MethodLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @methods [
    magic_link: PasswordlessWeb.App.MethodLive.MagicLink,
    sms: PasswordlessWeb.App.MethodLive.SMS
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
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/methods/#{socket.assigns.live_action}")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/methods/#{socket.assigns.live_action}")}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :magic_link) do
    assign(socket,
      page_title: gettext("Magic Link"),
      page_subtitle: gettext("Manage magic link settings")
    )
  end

  defp apply_action(socket, :sms) do
    assign(socket,
      page_title: gettext("SMS"),
      page_subtitle: gettext("Manage SMS settings")
    )
  end
end
