defmodule PasswordlessWeb.ContactController do
  use PasswordlessWeb, :controller

  def submit_form(conn, %{"message" => message}) do
    case apply_message_changeset(message) do
      {:ok, %{name: name, email: email, message: message}} ->
        Passwordless.Accounts.Notifier.deliver_contact_form_submission(email, name, message)

        conn
        |> put_flash(:info, gettext("Thank you for contacting us! We'll get back to you shortly"))
        |> redirect(to: ~p"/contact")

      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, gettext("Something went wrong"))
        |> redirect(to: ~p"/contact")
    end

    conn
    |> put_flash(:info, gettext("Thank you for contacting us! We'll get back to you shortly"))
    |> redirect(to: ~p"/contact")
  end

  # Private

  defp apply_message_changeset(params) do
    params
    |> build_message_changeset()
    |> Ecto.Changeset.apply_action(:insert)
  end

  defp build_message_changeset(params) do
    types = %{
      name: :string,
      email: :string,
      message: :string
    }

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:name, :email, :message])
    |> Database.ChangesetExt.validate_email()
  end
end
