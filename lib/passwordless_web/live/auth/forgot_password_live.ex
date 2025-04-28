defmodule PasswordlessWeb.Auth.ForgotPasswordLive do
  @moduledoc false

  use PasswordlessWeb, :live_view

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_form()
     |> assign(page_title: gettext("Forgot Password"))}
  end

  @impl true
  def handle_event("validate_email", %{"user" => user_params}, socket) do
    changeset =
      user_params
      |> build_email_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :user))}
  end

  @impl true
  def handle_event("send_email", %{"user" => user_params}, socket) do
    case apply_email_changeset(user_params) do
      {:ok, %{email: email}} ->
        with %User{} = user <- Accounts.get_user_by_email(email) do
          Accounts.deliver_user_reset_password_instructions(user, &url(~p"/auth/reset-password/#{&1}"))
        end

        info = gettext("If your email is in our system, you will receive instructions to reset your password shortly.")

        {:noreply,
         socket
         |> put_toast(:info, info, title: gettext("Success"))
         |> push_navigate(to: ~p"/auth/sign-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :user))}
    end
  end

  # Private

  defp assign_form(socket, changes \\ %{}) do
    assign(socket, form: to_form(build_email_changeset(changes), as: :user))
  end

  defp apply_email_changeset(params) do
    params
    |> build_email_changeset()
    |> Ecto.Changeset.apply_action(:insert)
  end

  defp build_email_changeset(params) do
    types = %{
      email: :string
    }

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Database.ChangesetExt.validate_email()
  end
end
