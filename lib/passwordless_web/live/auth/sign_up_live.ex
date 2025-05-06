defmodule PasswordlessWeb.Auth.SignUpLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Accounts
  alias Passwordless.Accounts.OTP
  alias Passwordless.Accounts.User
  alias Passwordless.Cache

  require Logger

  @interval :timer.seconds(1)
  @resend_interval 15

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    login_methods = [
      %{
        icon: "remix-mail-line",
        label: gettext("Email code"),
        value: "email_otp",
        description: nil
      },
      %{
        icon: "remix-lock-line",
        label: gettext("Password"),
        value: "password",
        description: nil
      }
    ]

    socket =
      socket
      |> ensure_temporary_token(params)
      |> assign_temporary_token(params)
      |> assign_resend(start?: socket.assigns.live_action == :otp_sent)
      |> assign(
        loading: false,
        code_errors: [],
        trigger_submit: false,
        error_message: nil,
        login_methods: login_methods
      )
      |> assign_form(Accounts.change_user_internal_registration(%User{}))
      |> assign_token_form()
      |> apply_action(socket.assigns.live_action)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_internal_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("submit", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params, via: :internal) do
      {:ok, user, _org, _membership} ->
        send_email_otp(socket, user)

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, error} ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Sign up failed: %{error}", error: inspect(error)), title: gettext("Error"))
         |> push_patch(to: ~p"/auth/sign-in")}
    end
  end

  @impl true
  def handle_event("validate_code", %{"auth" => %{"code" => _code}}, socket) when is_nil(socket.assigns.auth_user) do
    {:noreply, push_patch(socket, to: ~p"/auth/sign-in")}
  end

  @impl true
  def handle_event("validate_code", %{"auth" => %{"code" => code}}, socket) when is_binary(code) do
    if byte_size(String.trim(code)) < 6 do
      {:noreply, socket}
    else
      validation_result = Accounts.validate_user_otp(socket.assigns.auth_user, code)
      {:noreply, handle_validation(socket, validation_result)}
    end
  end

  @impl true
  def handle_event("validate_code", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("resend", _, socket) do
    case {socket.assigns[:auth_user], socket.assigns[:resend_enabled]} do
      {%User{} = user, true} -> send_email_otp(socket, user)
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:wait_for_resend, socket) do
    {:noreply, assign_resend(socket)}
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

  defp assign_token_form(socket, changes \\ %{}) do
    assign(socket, token_form: to_form(build_token_changeset(changes), as: :auth))
  end

  defp build_token_changeset(params) do
    types = %{sign_in_token: :string}
    Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
  end

  defp assign_temporary_token(socket, %{"token" => token}) when is_binary(token) do
    case Accounts.decode_user_temporary_token(token) do
      {:ok, token} -> assign(socket, temporary_token: token)
      _ -> assign(socket, temporary_token: nil)
    end
  end

  defp assign_temporary_token(socket, _), do: assign(socket, temporary_token: nil)

  defp assign_resend(%{assigns: %{temporary_token: token}} = socket, opts \\ []) do
    start? = Keyword.get(opts, :start?, false)

    if start? do
      case Cache.get({:countdown_seconds, token}) do
        :finished ->
          assign(socket, seconds_till_resend: nil, resend_enabled: true)

        seconds when is_integer(seconds) and seconds >= 1 ->
          Process.send_after(self(), :wait_for_resend, @interval)
          assign(socket, seconds_till_resend: seconds, resend_enabled: false)

        _ ->
          Process.send_after(self(), :wait_for_resend, @interval)
          Cache.put({:countdown_seconds, token}, @resend_interval, ttl: :timer.minutes(1))
          assign(socket, seconds_till_resend: @resend_interval, resend_enabled: false)
      end
    else
      case Cache.get({:countdown_seconds, token}) do
        :finished ->
          assign(socket, seconds_till_resend: nil, resend_enabled: true)

        seconds when is_integer(seconds) and seconds <= 1 ->
          Cache.put({:countdown_seconds, token}, :finished, ttl: :timer.minutes(10))
          assign(socket, seconds_till_resend: nil, resend_enabled: true)

        seconds when is_integer(seconds) ->
          Process.send_after(self(), :wait_for_resend, @interval)
          Cache.put({:countdown_seconds, token}, seconds - 1, ttl: :timer.minutes(1))
          assign(socket, seconds_till_resend: seconds - 1, resend_enabled: false)

        _ ->
          Cache.delete({:countdown_seconds, token})
          socket
      end
    end
  end

  defp ensure_temporary_token(%{assigns: %{live_action: :sign_up}} = socket, _params), do: socket

  defp ensure_temporary_token(%{assigns: %{live_action: :otp_sent}} = socket, %{"token" => token})
       when is_binary(token) do
    with {:ok, auth_user} <- Accounts.get_user_by_temporary_token(token),
         true <- Accounts.user_has_valid_otp?(auth_user) do
      assign(socket, auth_user: auth_user)
    else
      _ -> push_patch(socket, to: ~p"/auth/sign-in")
    end
  end

  defp send_email_otp(socket, %User{} = user) do
    with {:ok, otp} <- Accounts.insert_user_otp(user), {:ok, _sent_email} <- Accounts.deliver_email_otp(user, otp) do
      token = Accounts.generate_user_temporary_token(user)

      if Passwordless.config(:env) == :dev do
        Logger.info("----------- OTP ------------")
        Logger.info(otp.code)
      end

      {:noreply,
       socket
       |> assign(auth_user: user)
       |> assign_token_form()
       |> push_patch(to: ~p"/auth/sign-up/otp/#{token}")}
    else
      {:error, error} ->
        assign(socket, error_message: inspect(error))
    end
  end

  defp handle_validation(socket, {:ok, _otp}) do
    with %User{} = user <- socket.assigns[:auth_user],
         {:ok, sign_in_token} <- Accounts.generate_user_passwordless_token(user) do
      Process.send_after(self(), :trigger_submit, 500)

      socket
      |> assign(loading: true, code_errors: [])
      |> assign_token_form(%{sign_in_token: sign_in_token})
    else
      _ ->
        {:noreply, socket}
    end
  end

  defp handle_validation(socket, {:error, :too_many_incorrect_attempts}) do
    case socket.assigns[:auth_user] do
      %User{} = user ->
        Accounts.purge_user_otp(user)

        socket
        |> put_toast(:error, gettext("Too many incorrect attempts!"), title: gettext("Error"))
        |> push_patch(to: ~p"/auth/sign-in")

      _ ->
        {:noreply, socket}
    end
  end

  defp handle_validation(socket, {:error, :expired}) do
    case socket.assigns[:auth_user] do
      %User{} = user ->
        Accounts.purge_user_otp(user)

        socket
        |> put_toast(:error, gettext("Code has expired! Please request a new one."), title: gettext("Error"))
        |> push_patch(to: ~p"/auth/sign-in")

      _ ->
        {:noreply, socket}
    end
  end

  defp handle_validation(socket, {:error, :incorrect_code, attempt}) do
    case socket.assigns[:auth_user] do
      %User{} = user ->
        Accounts.fail_user_otp(user)

        error =
          gettext("incorrect code (attempt %{attempt} of %{max_attempts})",
            attempt: attempt,
            max_attempts: OTP.attempts()
          )

        changeset =
          %{code: nil}
          |> build_token_changeset()
          |> Ecto.Changeset.add_error(
            :code,
            error
          )

        assign(socket,
          token_form: to_form(changeset, as: :auth),
          code_errors: [error]
        )

      _ ->
        {:noreply, socket}
    end
  end

  defp handle_validation(socket, {:error, :not_found}) do
    socket
    |> put_toast(:error, gettext("Not a valid code. Sure you typed it correctly?"), title: gettext("Error"))
    |> push_patch(to: ~p"/auth/sign-in")
  end

  defp apply_action(socket, :sign_up), do: assign(socket, page_title: gettext("Sign up"))
  defp apply_action(socket, :otp_sent), do: assign(socket, page_title: gettext("Email code"))
end
