defmodule PasswordlessWeb.App.ActionLive.Edit do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.App

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, %{assigns: %{current_app: %App{} = current_app}} = socket) do
    action_template = Passwordless.get_action_template!(current_app, id)
    changeset = Passwordless.change_action_template(action_template)
    delete? = Map.has_key?(params, "delete")

    {:noreply,
     socket
     |> assign(delete?: delete?, action_template: action_template)
     |> assign_action_form(changeset)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"action_template" => action_template_params}, socket) do
    changeset =
      socket.assigns.action_template
      |> Passwordless.change_action_template(action_template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_action_form(socket, changeset)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(%{assigns: %{delete?: true, action_template: action_template}} = socket, _action, _params) do
    assign(socket,
      page_title: gettext("Delete action"),
      page_subtitle:
        gettext(
          "Are you sure you want to delete this action? This action will be permanently deleted, and all widgets or API integrations using this action will stop working."
        )
    )
  end

  defp apply_action(socket, _action, _params) do
    assign(socket,
      page_title: gettext("Action"),
      page_subtitle: gettext("Manage this action")
    )
  end

  defp assign_action_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, action_form: to_form(changeset))
  end
end
