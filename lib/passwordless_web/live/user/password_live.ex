defmodule PasswordlessWeb.User.PasswordLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Activity

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(has_password: User.has_password?(user))
      |> assign_form(User.current_password_changeset(user))
      |> apply_action(socket.assigns.live_action)

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/password")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/password")}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params, "current_password" => password}, socket) do
    user_params = Map.put(user_params, "current_password", password)

    changeset =
      socket.assigns.current_user
      |> User.current_password_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("submit", %{"user" => user_params, "current_password" => password}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, _user} ->
        put_toast(:info, gettext("Password has been updated."), title: gettext("Success"))

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("send_password_reset_email", _params, socket) do
    user = socket.assigns.current_user

    Accounts.deliver_user_reset_password_instructions(user, &url(~p"/auth/reset-password/#{&1}"))

    Activity.log_async(:user, :"user.request_password_reset", %{user: user, email: user.email})

    {:noreply,
     socket
     |> put_toast(:info, gettext("You will receive instructions to reset your password shortly."),
       title: gettext("Success")
     )
     |> push_patch(to: ~p"/app/password")}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Password")
    )
  end

  defp apply_action(socket, :change) do
    assign(socket,
      page_title: gettext("Reset Password"),
      page_subtitle:
        gettext("This will send a reset password link to the email '%{email}'. Continue?",
          email: user_email(socket.assigns.current_user)
        )
    )
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
