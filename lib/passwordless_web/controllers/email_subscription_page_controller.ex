defmodule PasswordlessWeb.EmailSubscriptionPageController do
  use PasswordlessWeb, :controller

  alias Passwordless.App
  alias Passwordless.Email
  alias Passwordless.EmailUnsubscribeLinkMapping

  action_fallback PasswordlessWeb.FallbackController

  def show(%Plug.Conn{} = conn, %{"token" => token}) when is_binary(token) do
    case Passwordless.get_unsubscribe_link(token) do
      {:ok, %App{} = app, %Email{} = email, %EmailUnsubscribeLinkMapping{} = mapping} ->
        render(conn, "show.html",
          app: app,
          form: build_unsubscribe_changeset(%{email: email.address}),
          token: EmailUnsubscribeLinkMapping.sign_token(mapping)
        )

      _ ->
        render(conn, "failure.html")
    end
  end

  def finalize(%Plug.Conn{} = conn, %{"form" => form}) do
    case apply_unsubscribe_changeset(form) do
      {:ok, %{token: token}} ->
        case Passwordless.unsubscribe_email(token, "ui-link") do
          {:ok, {%App{} = app, %Email{} = email}} -> render(conn, "success.html", app: app, email: email)
          _ -> render(conn, "failure.html")
        end

      {:error, %Ecto.Changeset{} = _changeset} ->
        render(conn, "failure.html")
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
