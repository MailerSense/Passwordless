defmodule PasswordlessWeb.App.ActionLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.ActionTemplate
  alias Passwordless.App

  @impl true
  def update(%{current_app: %App{} = app, action_template: %ActionTemplate{} = action_template} = assigns, socket) do
    changeset = Passwordless.change_action_template(app, action_template)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"action_template" => action_template_params}, socket) do
    action_template_params =
      Map.put(action_template_params, "rules", sample_rules())

    changeset =
      socket.assigns.current_app
      |> Passwordless.change_action_template(socket.assigns.action_template, action_template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"action_template" => action_template_params}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp sample_rules,
    do: [
      %{index: 0, enabled: true, condition: %{}, effects: %{}},
      %{index: 1, enabled: true, condition: %{}, effects: %{}},
      %{index: 2, enabled: true, condition: %{}, effects: %{}}
    ]
end
