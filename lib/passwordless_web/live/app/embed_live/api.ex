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
    case Passwordless.update_app(socket.assigns.app, app_params) do
      {:ok, app} ->
        socket =
          socket
          |> assign(app: app)
          |> assign_form(Passwordless.change_app(app))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("save", %{"app" => app_params}, socket) do
    case Passwordless.update_app(socket.assigns.app, app_params) do
      {:ok, app} ->
        socket =
          socket
          |> assign(app: app)
          |> assign_form(Passwordless.change_app(app))

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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(default_action: Ecto.Changeset.get_field(changeset, :default_action))
  end
end
