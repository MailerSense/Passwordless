defmodule PasswordlessWeb.Org.TeamLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias Passwordless.Security.Guard
  alias Passwordless.Security.Policy.Accounts, as: AccountsPolicy
  alias Passwordless.Security.Roles

  @impl true
  def update(assigns, socket) do
    changeset = Organizations.change_membership(assigns.membership)

    roles =
      Enum.map(Roles.org_role_descriptions(), fn {role, {description, color}} ->
        %{name: description, label: String.capitalize(Atom.to_string(role)), value: role, color: color}
      end)

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
