defmodule PasswordlessWeb.OrgController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.App
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Org

  @org_key "org_id"
  @app_key "app_id"

  def switch(conn, %{"org_id" => org_id}, user) do
    current_org = Organizations.get_org!(user, org_id)
    current_membership = Organizations.get_membership!(user, org_id)

    conn
    |> assign(:current_org, current_org)
    |> assign(:current_membership, current_membership)
    |> put_session(@org_key, current_org.id)
    |> put_session(@app_key, load_app(current_org))
    |> put_flash(:info, gettext("You're now in %{org_name}.", org_name: current_org.name))
    |> redirect(to: ~p"/home")
  end

  def accept_invitation(conn, %{"invitation_id" => invitation_id}, user) do
    membership = Organizations.accept_invitation!(user, invitation_id)

    conn
    |> assign(:current_org, membership.org)
    |> assign(:current_membership, membership)
    |> put_session(@org_key, membership.org.id)
    |> put_session(@app_key, load_app(membership.org))
    |> put_flash(:info, gettext("You're now in %{org_name}.", org_name: membership.org.name))
    |> redirect(to: ~p"/home")
  end

  # Private

  defp load_app(%Org{} = org) do
    case Organizations.preload_apps(org) do
      %Org{apps: [%App{} = app | _]} -> app.id
      _ -> nil
    end
  end

  defp load_app(_org), do: nil
end
