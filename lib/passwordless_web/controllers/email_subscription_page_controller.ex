defmodule PasswordlessWeb.EmailSubscriptionPageController do
  use PasswordlessWeb, :controller

  alias Passwordless.App
  alias Passwordless.Email
  alias Passwordless.EmailUnsubscribeLinkMapping

  def show(%Plug.Conn{} = conn, %{"token" => token}) when is_binary(token) do
    with {:ok, %App{} = app, %Email{} = email, %EmailUnsubscribeLinkMapping{} = mapping} <-
           Passwordless.get_unsubscribe_link(token) do
      render(conn, "show.html",
        app: app,
        form: build_message_changeset(%{email: email.address}),
        token: EmailUnsubscribeLinkMapping.sign_token(mapping)
      )
    end
  end

  # Private

  defp apply_message_changeset(params) do
    params
    |> build_message_changeset()
    |> Ecto.Changeset.apply_action(:insert)
  end

  defp build_message_changeset(params) do
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
