defmodule PasswordlessWeb.Org.TeamLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Membership
  alias Passwordless.Security.Guard
  alias Passwordless.Security.Policy.Accounts, as: AccountsPolicy

  @impl true
  def update(assigns, socket) do
    roles = Enum.map(Membership.roles(), fn role -> {Phoenix.Naming.humanize(role), role} end)
    changeset = Organizations.change_membership(assigns.membership)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(roles: roles)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"membership" => params}, socket) do
    changeset =
      socket.assigns.membership
      |> Organizations.change_membership(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"membership" => params}, %{assigns: %{membership: membership}} = socket) do
    case Organizations.update_membership(membership, params) do
      {:ok, membership} ->
        Passwordless.Activity.log(:"org.update_member", %{
          org: socket.assigns.current_org,
          user: socket.assigns.current_user,
          role: membership.role,
          target_user_id: membership.user_id
        })

        {:noreply,
         socket
         |> put_toast(:info, gettext("Member has been updated."), title: gettext("Success"))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
