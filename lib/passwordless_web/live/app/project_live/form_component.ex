defmodule PasswordlessWeb.App.ProjectLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Activity
  alias Passwordless.Organizations

  @impl true
  def update(%{project: project} = assigns, socket) do
    changeset = Passwordless.change_project(project, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      socket.assigns.project
      |> Passwordless.change_project(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.live_action, project_params)
  end

  # Private

  defp save_project(socket, :edit, project_params) do
    case Passwordless.update_project(socket.assigns.project, project_params) do
      {:ok, project} ->
        Activity.log_async(:project, :"project.update_profile", %{user: socket.assigns.current_user, project: project})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Project updated."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_project(socket, :new, project_params) do
    case Passwordless.create_project(socket.assigns.current_org, project_params) do
      {:ok, _project} ->
        Organizations.clear_cached_projects(socket.assigns.current_org)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Project created."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
