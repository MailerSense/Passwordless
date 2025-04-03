defmodule PasswordlessWeb.Org.EditLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.Accounts.User
  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Org

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    current_org = socket.assigns.current_org
    changeset = Organizations.change_org(current_org)

    {:noreply,
     socket
     |> assign_form(changeset)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/organization")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/organization")}
  end

  @impl true
  def handle_event("validate", %{"org" => org_params}, socket) do
    changeset =
      socket.assigns.current_org
      |> Organizations.change_org(org_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"org" => org_params}, socket) do
    case Organizations.update_org(socket.assigns.current_org, org_params) do
      {:ok, org} ->
        Activity.log_async(:org, :"org.update_profile", %{
          user: socket.assigns.current_user,
          org: org
        })

        current_user = assign_current_org(socket.assigns.current_user, org)

        socket =
          socket
          |> put_toast(:info, gettext("Organization settings has been saved."), title: gettext("Success"))
          |> assign(current_org: org, current_user: current_user)
          |> assign_form(Organizations.change_org(org))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Organization")
    )
  end

  defp apply_action(socket, :new) do
    assign(socket,
      page_title: gettext("Create organization"),
      page_subtitle:
        gettext(
          "Organizations represent the top level in your hierarchy. You'll be able to bundle a collection of teams within an organization as well as give organization-wide permissions to users."
        )
    )
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp assign_current_org(%User{current_org: %Org{id: id}} = user, %Org{id: id} = updated_org) do
    %User{user | current_org: updated_org}
  end

  defp assign_current_org(user, _org), do: user
end
