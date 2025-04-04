defmodule PasswordlessWeb.User.ChangeEmailComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Activity

  @impl true
  def update(assigns, socket) do
    changeset = User.email_changeset(assigns.current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> User.email_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("submit", %{"user" => user_params}, socket) do
    current_user = socket.assigns.current_user

    case Accounts.can_change_user_email?(current_user, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          current_user.email,
          &url(~p"/app/user/settings/confirm-email/#{&1}")
        )

        Activity.log_async(:"user.request_email_change", %{user: current_user, new_email: user_params["email"]})

        {:noreply,
         socket
         |> put_toast(:info, gettext("A link to confirm your e-mail change has been sent to the new address."),
           title: gettext("Success")
         )
         |> push_patch(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
