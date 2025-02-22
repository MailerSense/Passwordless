defmodule PasswordlessWeb.Auth.PasswordlessLive do
  @moduledoc """
  This module is used to handle the passwordless auth flow.
  A user enters their email and submits. If no user exists for the user, then one is created with a random password.
  A user will fill in their name at the onboarding screen.

  Process:
  1: User submits email.
  2: Find or create a user, set it as assigns.auth_user
  3: Push patch to /passwordless/sign-in-code/:token
  4: User enters code that was sent to their email.
  5: A form is submited that POSTs a token to UserSessionController.create_from_token/2
  6: User is logged in
  """
  use PasswordlessWeb, :live_view

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User

  require Logger

  @interval :timer.seconds(1)
  @resend_interval 15

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(
        user_return_to: Map.get(params, "user_return_to", nil),
        step: :sign_in,
        auth_user: nil,
        resend_enabled: false,
        seconds_till_resend: nil
      )
      |> assign_form(User.naive_email_changeset(%User{}))
      |> apply_action(socket.assigns.live_action, %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_email", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> User.naive_email_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("submit_email", %{"user" => %{"email" => email}}, socket) do
    send_magic_link(socket, email)
  end

  @impl true
  def handle_event("resend", _, socket) do
    case {socket.assigns[:auth_user], socket.assigns[:resend_enabled]} do
      {%User{} = user, true} ->
        send_magic_link(socket, user.email)

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:wait_for_resend, socket) do
    case socket.assigns[:seconds_till_resend] do
      seconds when is_integer(seconds) and seconds <= 1 ->
        {:noreply, assign(socket, seconds_till_resend: nil, resend_enabled: true)}

      seconds when is_integer(seconds) ->
        Process.send_after(self(), :wait_for_resend, @interval)
        {:noreply, update(socket, :seconds_till_resend, &(&1 - 1))}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp apply_action(socket, :sign_in, _params), do: assign(socket, page_title: gettext("Magic Link"), error_message: nil)

  defp apply_action(socket, :link_sent, _params),
    do: assign(socket, page_title: gettext("Magic Link Sent!"), error_message: nil)

  defp send_magic_link(socket, email) when is_binary(email) do
    case Accounts.get_or_register_user(email, %{}, via: :passwordless) do
      {:ok, %User{} = user} ->
        case Accounts.deliver_magic_link(user, &url(~p"/auth/sign-in/passwordless/complete/#{&1}")) do
          {:ok, _sent_email} ->
            Process.send_after(self(), :wait_for_resend, @interval)

            {:noreply,
             assign(socket,
               auth_user: user,
               step: :link_sent,
               resend_enabled: false,
               seconds_till_resend: @resend_interval
             )}

          {:error, error} ->
            assign(socket, error_message: inspect(error))
        end

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
