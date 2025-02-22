defmodule PasswordlessWeb.Auth.RegistrationLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(trigger_submit: false)
      |> assign_form(%User{})
      |> assign(page_title: gettext("Sign Up"))

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("submit", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params, via: :password) do
      {:ok, user} ->
        case Accounts.deliver_user_confirmation_instructions(user, &url(~p"/auth/confirm/#{&1}")) do
          {:ok, _} ->
            socket =
              socket
              |> assign(trigger_submit: true)
              |> assign_form(user)

            {:noreply, socket}

          {:error, _} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "User has been registered but email delivery failed. Please contact support."
             )}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # Private

  defp assign_form(socket, %User{} = user, changes \\ %{}) do
    assign(socket, form: to_form(Accounts.change_user_registration(user, changes)))
  end
end
