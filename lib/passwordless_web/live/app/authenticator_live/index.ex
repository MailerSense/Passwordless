defmodule PasswordlessWeb.App.AuthenticatorLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @authenticators [
    magic_link: PasswordlessWeb.App.AuthenticatorLive.MagicLink,
    sms: PasswordlessWeb.App.AuthenticatorLive.SMS,
    whatsapp: PasswordlessWeb.App.AuthenticatorLive.Whatsapp,
    email: PasswordlessWeb.App.AuthenticatorLive.Email,
    totp: PasswordlessWeb.App.AuthenticatorLive.TOTP,
    security_key: PasswordlessWeb.App.AuthenticatorLive.SecurityKey,
    passkey: PasswordlessWeb.App.AuthenticatorLive.Passkey,
    recovery_codes: PasswordlessWeb.App.AuthenticatorLive.RecoveryCodes
  ]

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign(module: Keyword.fetch!(@authenticators, socket.assigns.live_action))}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/authenticators/#{socket.assigns.live_action}")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/authenticators/#{socket.assigns.live_action}")}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, _action, _params) do
    assign(socket,
      page_title: gettext("Authenticators"),
      page_subtitle: gettext("Manage authenticator settings")
    )
  end
end
