defmodule PasswordlessWeb.App.ActorLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Actor

  @impl true
  def update(%{actor: %Actor{} = actor} = assigns, socket) do
    changeset = Passwordless.change_actor(actor, %{})

    locales = Enum.map(Passwordless.Locale.languages(), fn {code, name} -> {name, code} end)

    icon_mapping = fn
      k when is_atom(k) -> "flag-#{k}"
      k when is_binary(k) -> "flag-#{k}"
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(locales: locales, icon_mapping: icon_mapping)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"actor" => actor_params}, socket) do
    changeset =
      socket.assigns.actor
      |> Passwordless.change_actor(actor_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"actor" => actor_params}, socket) do
    save_actor(socket, socket.assigns.live_action, actor_params)
  end

  # Private

  defp save_actor(socket, :edit, actor_params) do
    case Passwordless.update_actor(socket.assigns.actor, actor_params) do
      {:ok, actor} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Actor updated."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_actor(socket, :new, actor_params) do
    case Passwordless.create_actor(socket.assigns.current_org, actor_params) do
      {:ok, _actor} ->
        Organizations.clear_cached_actors(socket.assigns.current_org)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Actor created."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
