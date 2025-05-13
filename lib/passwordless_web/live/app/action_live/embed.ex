defmodule PasswordlessWeb.App.ActionLive.Embed do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.App

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, %{assigns: %{current_app: %App{} = current_app}} = socket) do
    action_template = Passwordless.get_action_template!(current_app, id)
    changeset = Passwordless.change_action_template(current_app, action_template)

    {:noreply,
     socket
     |> assign(action_template: action_template)
     |> assign_action_form(changeset)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("validate", %{"action_template" => action_template_params}, socket) do
    changeset =
      socket.assigns.current_app
      |> Passwordless.change_action_template(socket.assigns.action_template, action_template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_action_form(socket, changeset)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/actions/#{socket.assigns.action_template}/embed")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/actions/#{socket.assigns.action_template}/embed")}
  end

  @impl true
  def handle_event("delete_action_template", _params, socket) do
    action_template = socket.assigns.action_template

    case Passwordless.delete_action_template(action_template) do
      {:ok, _action_template} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("Action has been deleted."), title: gettext("Success"))
         |> push_navigate(to: ~p"/actions")}

      _ ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Failed to delete action!"), title: gettext("Error"))
         |> push_patch(to: ~p"/actions")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :delete) do
    assign(socket,
      page_title: gettext("Delete action"),
      page_subtitle:
        gettext(
          "Are you sure you want to delete this action? This action will be permanently deleted, and all widgets or API integrations using this action will stop working."
        )
    )
  end

  defp apply_action(socket, _action) do
    assign(socket,
      page_title: gettext("Embed Action"),
      page_subtitle: gettext("Manage this action")
    )
  end

  defp assign_action_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, action_form: to_form(changeset))
  end
end
