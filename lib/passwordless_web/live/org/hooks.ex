defmodule PasswordlessWeb.Org.Hooks do
  @moduledoc """
  Org related on_mount hooks used by live views. These are used in the router or within a specific live view if need be.
  Docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1
  """
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import Phoenix.Component
  import Phoenix.LiveView

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org

  @cache_ttl :timer.minutes(3 * 60)

  def on_mount(:fetch_current_org, _params, session, socket) do
    socket =
      socket
      |> assign_current_membership(session)
      |> assign_current_org()
      |> assign_current_org_user()

    {:cont, socket}
  end

  def on_mount(:require_current_org, _params, _session, socket) do
    case {socket.assigns[:current_org], socket.assigns[:current_membership]} do
      {%Org{}, %Membership{}} ->
        {:cont, socket}

      _ ->
        socket = put_flash(socket, :error, gettext("You must belong to an organization to access this page."))
        {:halt, redirect(socket, to: ~p"/app/home")}
    end
  end

  def on_mount(:require_org_member, _params, _session, socket) do
    require_minimal_org_role(socket, :member)
  end

  def on_mount(:require_org_admin, _params, _session, socket) do
    require_minimal_org_role(socket, :admin)
  end

  def on_mount(:require_org_owner, _params, _session, socket) do
    require_minimal_org_role(socket, :owner)
  end

  # Private

  defp assign_current_org(socket) do
    assign_new(socket, :current_org, fn ->
      case socket.assigns[:current_membership] do
        %Membership{org: %Org{} = org} -> org
        _ -> nil
      end
    end)
  end

  defp assign_current_membership(socket, session) do
    assign_new(socket, :current_membership, fn ->
      case {socket.assigns[:current_user], session["org_id"]} do
        {%User{} = user, org_id} when is_binary(org_id) ->
          Organizations.get_membership!(user, org_id)

        _ ->
          nil
      end
    end)
  end

  defp assign_current_org_user(
         %{
           assigns: %{
             current_user: %User{},
             current_org: %Org{} = current_org,
             current_membership: %Membership{} = current_membership
           }
         } = socket
       ) do
    update(socket, :current_user, fn current_user ->
      %User{current_user | current_org: current_org, current_membership: current_membership}
    end)
  end

  defp assign_current_org_user(socket), do: socket

  defp require_minimal_org_role(socket, role) when is_atom(role) do
    with %Membership{} = membership <- socket.assigns[:current_membership],
         true <- Membership.is_or_higher?(membership, role) do
      {:cont, socket}
    else
      _ ->
        socket = put_flash(socket, :error, gettext("You do not have permission to access this page."))
        {:halt, redirect(socket, to: PasswordlessWeb.Helpers.home_path(socket.assigns.current_user))}
    end
  end
end
