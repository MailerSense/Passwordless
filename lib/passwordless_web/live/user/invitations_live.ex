defmodule PasswordlessWeb.User.InvitationsLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.Accounts
  alias Passwordless.Activity
  alias Passwordless.Organizations

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Invitations")
     |> assign_invitations()}
  end

  @impl true
  def handle_event("accept_invitation", %{"id" => id}, socket) do
    membership = Organizations.accept_invitation!(socket.assigns.current_user, id)
    Organizations.clear_cached_orgs(socket.assigns.current_user)

    Activity.log(:org, :"org.accept_invitation", %{
      user: socket.assigns.current_user,
      org_id: membership.org_id,
      membership_id: membership.id
    })

    {:noreply,
     socket
     |> put_flash(:info, gettext("Invitation was accepted."))
     |> assign_invitations()}
  end

  @impl true
  def handle_event("reject_invitation", %{"id" => id}, socket) do
    invitation = Organizations.reject_invitation!(socket.assigns.current_user, id)

    Activity.log(:org, :"org.reject_invitation", %{
      user: socket.assigns.current_user,
      org_id: invitation.org_id
    })

    {:noreply,
     socket
     |> put_flash(:info, gettext("Invitation was rejected."))
     |> assign_invitations()}
  end

  @impl true
  def handle_event("confirmation_resend", _, socket) do
    Accounts.deliver_user_confirmation_instructions(
      socket.assigns.current_user,
      &url(~p"/app/user/settings/confirm-email/#{&1}")
    )

    {:noreply, put_flash(socket, :info, gettext("You will receive an e-mail with instructions shortly."))}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_invitations(socket) do
    invitations = Organizations.list_invitations_by_user(socket.assigns.current_user)
    assign(socket, :invitations, invitations)
  end
end
