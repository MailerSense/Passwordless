defmodule PasswordlessWeb.App.MethodLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @methods [
    magic_link: PasswordlessWeb.App.MethodLive.MagicLink,
    sms: PasswordlessWeb.App.MethodLive.SMS,
    email: PasswordlessWeb.App.MethodLive.Email,
    authenticator: PasswordlessWeb.App.MethodLive.Authenticator,
    security_key: PasswordlessWeb.App.MethodLive.SecurityKey,
    passkey: PasswordlessWeb.App.MethodLive.Passkey,
    recovery_codes: PasswordlessWeb.App.MethodLive.RecoveryCodes
  ]

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    sms_learn? = Map.has_key?(params, "sms_learn")

    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign(sms_learn?: sms_learn?)
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

  defp apply_action(socket, action, %{"sms_learn" => _}) do
    assign(socket,
      page_title: gettext("SMS OTP"),
      page_subtitle:
        gettext(
          "Learn how to use SMS OTP for your app. SMS OTP is a simple and secure way to verify your users. It is a great way to get started with Passwordless."
        )
    )
  end

  defp apply_action(socket, _action, _params) do
    assign(socket,
      page_title: gettext("Methods"),
      page_subtitle: gettext("Manage magic link settings")
    )
  end
end
