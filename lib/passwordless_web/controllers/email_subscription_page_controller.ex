defmodule PasswordlessWeb.EmailSubscriptionPageController do
  use PasswordlessWeb, :controller

  alias Passwordless.App
  alias Passwordless.Email
  alias Passwordless.EmailUnsubscribeLinkMapping

  action_fallback PasswordlessWeb.FallbackController

  def show(%Plug.Conn{} = conn, %{"token" => token}) when is_binary(token) do
    with {:ok, %App{} = app, %Email{} = email, %EmailUnsubscribeLinkMapping{} = mapping} <-
           Passwordless.get_unsubscribe_link(token) do
      render(conn, "show.html",
        app: app,
        form: build_unsubscribe_changeset(%{email: email.address}),
        token: EmailUnsubscribeLinkMapping.sign_token(mapping)
      )
    end
  end

  def finalize(%Plug.Conn{} = conn, %{"form" => form}) do
    case apply_unsubscribe_changeset(form) do
      {:ok, %{token: token}} ->
        with {:ok, %App{} = app, %Email{} = email, %EmailUnsubscribeLinkMapping{} = mapping} <-
               Passwordless.get_unsubscribe_link(token) do
          render(conn, "success.html", app: app)
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, gettext("Something went wrong"))
        |> render("show.html", form: changeset)
    end
  end

  # Private

  defp apply_unsubscribe_changeset(params) do
    params
    |> build_unsubscribe_changeset()
    |> Ecto.Changeset.apply_action(:insert)
  end

  defp build_unsubscribe_changeset(params) do
    types = %{
      token: :string,
      email: :string
    }

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:email])
    |> Database.ChangesetExt.validate_email()
  end
end
