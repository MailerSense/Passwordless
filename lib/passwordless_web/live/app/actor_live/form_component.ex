defmodule PasswordlessWeb.App.ActorLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Locale

  @impl true
  def update(%{current_app: %App{} = app, actor: %Actor{} = actor} = assigns, socket) do
    changeset = Passwordless.change_actor(app, actor)
    languages = Enum.map(Actor.languages(), fn code -> {Keyword.fetch!(Locale.languages(), code), code} end)

    flag_mapping = fn
      nil -> "flag-gb"
      "en" -> "flag-gb"
      :en -> "flag-gb"
      code -> "flag-#{code}"
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(languages: languages, flag_mapping: flag_mapping)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"actor" => actor_params}, socket) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    changeset =
      app
      |> Passwordless.change_actor(actor, actor_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"actor" => actor_params}, socket) do
    save_actor(socket, socket.assigns.live_action, actor_params)
  end

  # Private

  defp save_actor(socket, :edit, actor_params) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.update_actor(app, actor, actor_params) do
      {:ok, _actor} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("User has been updated."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_actor(socket, :new, actor_params) do
    case Passwordless.create_actor(socket.assigns.current_app, actor_params) do
      {:ok, _actor} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("User has been created."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
