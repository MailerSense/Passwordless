defmodule PasswordlessWeb.Auth.SignInLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(form: to_form(%{}, as: :user))
      |> assign(email: Phoenix.Flash.get(socket.assigns.flash, :email))
      |> assign(page_title: gettext("Sign In"))

    {:ok, socket, temporary_assigns: [email: nil]}
  end

  @impl true
  def handle_event(_action, _params, socket) do
    {:noreply, socket}
  end
end
