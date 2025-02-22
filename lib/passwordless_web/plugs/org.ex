defmodule PasswordlessWeb.Plugs.Org do
  @moduledoc false
  use PasswordlessWeb, :verified_routes

  import Phoenix.Controller
  import Plug.Conn

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org

  @org_key "org_id"

  def fetch_current_org(%Plug.Conn{} = conn, _opts) do
    case conn.assigns[:current_user] do
      %User{} = user ->
        case load_org(user, get_session(conn, @org_key)) do
          %Org{} = org ->
            membership = Organizations.get_membership!(user, org.id)

            conn
            |> assign(:current_org, org)
            |> assign(:current_user, %User{user | current_org: org, current_membership: membership})
            |> assign(:current_membership, membership)
            |> put_session(@org_key, org.id)

          _ ->
            conn
        end

      _ ->
        conn
        |> put_flash(:error, "You need to be signed in to access this page!")
        |> redirect(to: "/")
    end
  end

  # Private

  defp load_org(%User{} = user, org_id) when is_binary(org_id) do
    case Organizations.get_org(user, org_id) do
      %Org{} = org -> org
      _ -> load_org(user, nil)
    end
  end

  defp load_org(%User{} = user, _org_id) do
    case Accounts.preload_user_memberships(user) do
      %User{memberships: [%Membership{org: %Org{} = org} | _]} -> org
      _ -> nil
    end
  end
end
