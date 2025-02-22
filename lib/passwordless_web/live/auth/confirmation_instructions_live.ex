defmodule PasswordlessWeb.Auth.ConfirmationInstructionsLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: :user))}
  end

  @impl true
  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    with %User{} = user <- Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(user, &url(~p"/auth/confirm/#{&1}"))
    end

    info =
      gettext(
        "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/auth/confirm")}
  end
end
