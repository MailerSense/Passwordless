defmodule PasswordlessWeb.App.ActorLive.Edit do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Actor

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    actor = Passwordless.get_actor!(socket.assigns.current_app, id)
    changeset = Passwordless.change_actor(actor)
    languages = Enum.map(Passwordless.Locale.languages(), fn {code, name} -> {name, code} end)
    states = Enum.map(Actor.states(), fn state -> {Phoenix.Naming.humanize(state), state} end)

    {:noreply,
     socket
     |> assign(actor: actor, states: states, languages: languages)
     |> assign_form(changeset)
     |> assign_emails(actor)
     |> assign_phones(actor)
     |> apply_action(socket.assigns.live_action, actor)}
  end

  @impl true
  def handle_event("save", %{"actor" => actor_params}, socket) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.update_actor(app, actor, actor_params) do
      {:ok, actor} ->
        changeset =
          actor
          |> Passwordless.change_actor()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(actor: actor)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"actor" => actor_params}, socket) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.update_actor(app, actor, actor_params) do
      {:ok, actor} ->
        changeset =
          actor
          |> Passwordless.change_actor()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(actor: actor)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/users/#{socket.assigns.actor}/edit")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/users/#{socket.assigns.actor}/edit")}
  end

  @impl true
  def handle_event("delete_actor", _params, socket) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.delete_actor(app, actor) do
      {:ok, _actor} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("actor deleted successfully."))
         |> push_navigate(to: ~p"/app/users")}

      {:error, _} ->
        {:noreply,
         socket
         |> LiveToast.put_toast(:error, gettext("Failed to delete actor!"))
         |> push_patch(to: ~p"/app/users/#{actor}/edit")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp apply_action(socket, :edit, %Actor{} = actor) do
    assign(socket, page_title: actor.name)
  end

  defp apply_action(socket, :delete, _actor) do
    assign(socket,
      page_title: gettext("Are you sure?"),
      page_subtitle: gettext("Are you sure you want to delete this actor? This action cannot be undone.")
    )
  end

  defp assign_emails(socket, %Actor{} = actor) do
    assign(socket, emails: Passwordless.list_emails(socket.assigns.current_app, actor))
  end

  defp assign_phones(socket, %Actor{} = actor) do
    assign(socket, phones: Passwordless.list_phones(socket.assigns.current_app, actor))
  end
end
