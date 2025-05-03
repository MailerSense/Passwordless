defmodule PasswordlessWeb.User.ProfileLive do
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
    socket =
      socket
      |> assign_form(User.profile_changeset(socket.assigns.current_user))
      |> apply_action(socket.assigns.live_action)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> User.profile_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("submit", %{"user" => user_params}, socket) do
    update_profile(socket, user_params)
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/profile")}
  end

  @impl true
  def handle_event("close_slide_over", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/profile")}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp update_profile(socket, user_params) do
    case Accounts.update_user_profile(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        Activity.log_async(:"user.update_profile", %{user: user})

        socket =
          socket
          |> put_toast(:info, gettext("Profile has been updated."), title: gettext("Success"))
          |> assign(current_user: user)
          |> assign_form(User.profile_changeset(user))

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> put_toast(:error, gettext("Failed to update profile!"), title: gettext("Error"))
          |> assign_form(changeset)

        {:noreply, socket}
    end
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp apply_action(socket, :change_email) do
    assign(socket,
      page_title: gettext("Change email"),
      page_subtitle: gettext("Update your account email address. We'll send you a one-time code to confirm.")
    )
  end

  defp apply_action(socket, _) do
    assign(socket,
      page_title: gettext("Profile")
    )
  end
end
