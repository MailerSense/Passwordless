defmodule PasswordlessWeb.Project.Hooks do
  @moduledoc """
  Org related on_mount hooks used by live views. These are used in the router or within a specific live view if need be.
  Docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1
  """
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import Phoenix.Component

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Org
  alias Passwordless.Project

  def on_mount(:fetch_current_project, _params, session, socket) do
    socket =
      socket
      |> assign_current_project(session)
      |> assign_current_project_user()
      |> assign_org_projects()

    {:cont, socket}
  end

  # Private

  defp assign_current_project(socket, session) do
    assign_new(socket, :current_project, fn ->
      case {socket.assigns[:current_org], session["project_id"]} do
        {%Org{} = org, project_id} when is_binary(project_id) -> Passwordless.get_project!(org, project_id)
        _ -> nil
      end
    end)
  end

  defp assign_org_projects(%{assigns: %{current_org: %Org{} = org}} = socket) do
    socket = assign_new(socket, :org_projects, fn -> Organizations.list_cached_projects(org) end)

    update(socket, :current_user, fn current_user -> %User{current_user | all_projects: socket.assigns[:org_projects]} end)
  end

  defp assign_org_projects(socket), do: socket

  defp assign_current_project_user(
         %{assigns: %{current_user: %User{}, current_project: %Project{} = current_project}} = socket
       ) do
    update(socket, :current_user, fn current_user ->
      %User{current_user | current_project: current_project}
    end)
  end

  defp assign_current_project_user(socket), do: socket
end
