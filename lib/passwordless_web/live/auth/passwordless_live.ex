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
        step: :sign_in,
        auth_user: nil,
        resend_enabled: false,
        seconds_till_resend: nil,
        sign_in_token: nil,
        trigger_submit: false
      )
      |> assign_form(User.naive_email_changeset(%User{}))
      |> apply_action(socket.assigns.live_action, params)

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
    send_email_otp(socket, email)
  end

  # Handle nil user
  @impl true
  def handle_event("validate_code", %{"auth" => %{"code" => _code}}, socket) when is_nil(socket.assigns.auth_user) do
    {:noreply, push_patch(socket, to: ~p"/auth/sign-in/passwordless")}
  end

  @impl true
  def handle_event("validate_code", %{"auth" => %{"code" => code}}, socket) when byte_size(code) >= 6 do
    validation_result = Accounts.validate_user_otp(socket.assigns.auth_user, code)
    {:noreply, handle_validation(socket, validation_result)}
  end

  @impl true
  def handle_event("validate_code", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("resend", _, socket) do
    case {socket.assigns[:auth_user], socket.assigns[:resend_enabled]} do
      {%User{} = user, true} ->
        send_email_otp(socket, user.email)

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
  def handle_info(:trigger_submit, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  @impl true
  def handle_info(_params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp apply_action(socket, :sign_in, _params), do: assign(socket, page_title: gettext("Email Code"), error_message: nil)

  defp apply_action(socket, :otp_sent, %{"token" => token}) when is_binary(token) do
    case socket.assigns[:auth_user] do
      %User{} ->
        socket

      _ ->
        # Re-assign page variables if this is remounted (eg. socket disconnected)
        # This can happen on mobile devices when user switches to mail app to copy/paste code
        {:ok, auth_user} = Accounts.get_user_by_temporary_token(token)

        if Accounts.user_has_valid_otp?(auth_user),
          do: assign(socket, auth_user: auth_user),
          else: push_patch(socket, to: ~p"/auth/sign-in")
    end
  end

  defp send_email_otp(socket, email) when is_binary(email) do
    case Accounts.get_or_register_user(email, %{}, via: :passwordless) do
      {:ok, %User{} = user} ->
        with {:ok, otp} <- Accounts.insert_user_otp(user), {:ok, _sent_email} <- Accounts.deliver_otp(user, otp) do
          token = Accounts.generate_user_temporary_token(user)
          Process.send_after(self(), :wait_for_resend, @interval)

          {:noreply,
           socket
           |> assign(
             step: :otp_sent,
             auth_user: user,
             token_form: to_form(build_token_changeset(), as: :auth),
             seconds_till_resend: @resend_interval,
             resend_enabled: false
           )
           |> push_patch(to: ~p"/auth/sign-in/passwordless/otp#{token}")}
        else
          {:error, error} ->
            assign(socket, error_message: inspect(error))
        end

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp build_token_changeset(params \\ %{}) do
    types = %{
      code: :number,
      sign_in_token: :string
    }

    Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
  end

  defp handle_validation(socket, {:ok, _user_code}) do
    case socket.assigns[:auth_user] do
      %User{} = user ->
        Accounts.purge_user_otp(user)

        {:ok, sign_in_token} = Accounts.generate_user_passwordless_token(user)

        changeset =
          build_token_changeset(%{
            sign_in_token: sign_in_token,
            user_return_to: socket.assigns.user_return_to
          })

        Process.send_after(self(), :trigger_submit, 500)

        assign(socket, token_form: to_form(changeset, as: :auth), loading: true)

      _ ->
        {:noreply, socket}
    end
  end

  defp handle_validation(socket, {:error, :too_many_incorrect_attempts}) do
    case socket.assigns[:auth_user] do
      %User{} = user ->
        Accounts.purge_user_otp(user)

        socket
        |> push_patch(to: ~p"/auth/sign-in/passwordless")
        |> put_flash(:error, gettext("Too many incorrect attempts!"))

      _ ->
        {:noreply, socket}
    end
  end

  defp handle_validation(socket, {:error, :expired}) do
    case socket.assigns[:auth_user] do
      %User{} = user ->
        Accounts.purge_user_otp(user)

        socket
        |> push_patch(to: ~p"/auth/sign-in/passwordless")
        |> put_flash(:error, gettext("Not a valid code. Sure you typed it correctly?"))

      _ ->
        {:noreply, socket}
    end
  end

  defp handle_validation(socket, {:error, :incorrect_code}) do
    case socket.assigns[:auth_user] do
      %User{} = user ->
        Accounts.fail_user_otp(user)

        socket
        |> assign(:error_message, gettext("Not a valid code. Sure you typed it correctly?"))
        |> assign(:enable_resend?, true)

      _ ->
        {:noreply, socket}
    end
  end

  defp handle_validation(socket, {:error, :not_found}) do
    socket
    |> push_patch(to: ~p"/auth/sign-in/passwordless")
    |> put_flash(:error, gettext("Not a valid code. Sure you typed it correctly?"))
  end
end
