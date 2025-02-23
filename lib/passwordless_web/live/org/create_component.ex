defmodule PasswordlessWeb.Org.CreateComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Accounts.User
  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Org

  @impl true
  def update(%{org: org} = assigns, socket) do
    changeset = Organizations.change_org(org, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"org" => org_params}, socket) do
    changeset =
      socket.assigns.org
      |> Organizations.change_org(org_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"org" => org_params}, socket) do
    save_org(socket, socket.assigns.live_action, org_params)
  end

  # Private

  defp save_org(socket, :edit, org_params) do
    case Organizations.update_org(socket.assigns.org, org_params) do
      {:ok, org} ->
        Activity.log_async(:org, :"org.update_profile", %{user: socket.assigns.current_user, org: org})

        current_user = assign_current_org(socket.assigns.current_user, org)

        {:noreply,
         socket
         |> assign(current_user: current_user)
         |> put_flash(:info, gettext("Organization updated."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_org(socket, :new, org_params) do
    case Organizations.create_org_with_owner(socket.assigns.current_user, org_params) do
      {:ok, _org, _membership} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Organization created."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp assign_current_org(%User{current_org: %Org{id: id}} = user, %Org{id: id} = updated_org) do
    %User{user | current_org: updated_org}
  end

  defp assign_current_org(user, _org), do: user
end
