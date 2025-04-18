defmodule PasswordlessWeb.App.EmbedLive.API do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    changeset = Passwordless.change_app(app)

    actions =
      Enum.map(App.actions(), fn action ->
        {Phoenix.Naming.humanize(action), action}
      end)

    icon_mapping = fn
      nil -> "remix-checkbox-circle-fill"
      "allow" -> "remix-checkbox-circle-fill"
      :allow -> "remix-checkbox-circle-fill"
      "block" -> "remix-close-circle-fill"
      :block -> "remix-close-circle-fill"
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       actions: actions,
       icon_mapping: icon_mapping
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"app" => app_params}, socket) do
    changeset =
      socket.assigns.app
      |> Passwordless.change_app(app_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(default_action: Ecto.Changeset.get_field(changeset, :default_action))
  end
end
