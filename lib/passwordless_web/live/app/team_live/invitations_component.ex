defmodule PasswordlessWeb.Org.TeamLive.InvitationsComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Invitation
  alias Passwordless.Organizations.Org
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: Invitation,
    default_order: %{
      order_by: [:email],
      order_directions: [:desc]
    }
  ]

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_invitations()}
  end

  @impl true
  def handle_event("delete_invitation", %{"id" => id}, socket) do
    invitation = Organizations.get_invitation_by_org!(socket.assigns.current_org, id)

    case Organizations.delete_invitation(invitation) do
      {:ok, invitation} ->
        Activity.log(:org, :"org.delete_invitation", %{
          org: socket.assigns.current_org,
          user: socket.assigns.current_user,
          email: invitation.email
        })

        {:noreply,
         socket
         |> put_flash(:info, gettext("Invitation deleted."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete invitation!"))
         |> push_navigate(to: socket.assigns.return_to)}
    end
  end

  @impl true
  def handle_event("resend_invitation", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Invitation resent successfully."))
     |> push_navigate(to: socket.assigns.return_to)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_invitations(socket) do
    case socket.assigns[:current_org] do
      %Org{} = org ->
        query = Invitation.get_by_org(org)
        {invitations, meta} = DataTable.search(query, %{}, @data_table_opts)
        assign(socket, invitations: invitations, meta: meta)

      _ ->
        socket
    end
  end
end
