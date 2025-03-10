defmodule PasswordlessWeb.App.ActorLive.Edit do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Actor
  alias Passwordless.Locale

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, url, socket) do
    actor = Passwordless.get_actor!(socket.assigns.current_app, id)
    changeset = Passwordless.change_actor(actor)
    languages = Enum.map(Actor.languages(), fn code -> {Keyword.fetch!(Locale.languages(), code), code} end)

    flag_mapping = fn
      nil -> "flag-gb"
      "en" -> "flag-gb"
      :en -> "flag-gb"
      code -> "flag-#{code}"
    end

    socket =
      socket
      |> assign(actor: actor, languages: languages, flag_mapping: flag_mapping)
      |> assign_form(changeset)
      |> assign_emails(actor)
      |> assign_phones(actor)
      |> assign_identities(actor)
      |> apply_action(socket.assigns.live_action, actor)

    params
    |> Map.drop(["id"])
    |> handle_params(url, socket)
  end

  @impl true
  def handle_params(%{"email_id" => email_id} = params, url, socket) do
    email = Passwordless.get_email!(socket.assigns.current_app, socket.assigns.actor, email_id)
    socket = assign(socket, email: email)

    params
    |> Map.drop(["email_id"])
    |> handle_params(url, socket)
  end

  @impl true
  def handle_params(%{"phone_id" => phone_id} = params, url, socket) do
    phone = Passwordless.get_phone!(socket.assigns.current_app, socket.assigns.actor, phone_id)
    socket = assign(socket, phone: phone)

    params
    |> Map.drop(["phone_id"])
    |> handle_params(url, socket)
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"actor" => actor_params}, socket) do
    save_actor(socket, actor_params)
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
      {:ok, actor} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("User \"%{name}\" has been deleted.", name: actor_name(actor)),
           title: gettext("Success")
         )
         |> push_navigate(to: ~p"/app/users")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Failed to delete actor!"), title: gettext("Error"))
         |> push_patch(to: ~p"/app/users/#{actor}/edit")}
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
    |> assign(user_name: Ecto.Changeset.get_field(changeset, :name))
    |> assign(user_state: Ecto.Changeset.get_field(changeset, :state))
    |> assign(user_active: Ecto.Changeset.get_field(changeset, :active))
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

  defp apply_action(socket, :new_email, _actor) do
    assign(socket,
      page_title: gettext("Add email"),
      page_subtitle: nil
    )
  end

  defp apply_action(socket, :edit_email, _actor) do
    assign(socket,
      page_title: gettext("Edit email"),
      page_subtitle: nil
    )
  end

  defp apply_action(socket, :delete_email, _actor) do
    assign(socket,
      page_title: gettext("Are you sure?"),
      page_subtitle: gettext("Are you sure you want to delete this email? This action cannot be undone.")
    )
  end

  defp apply_action(socket, :edit_phone, _actor) do
    assign(socket,
      page_title: gettext("Edit phone"),
      page_subtitle: gettext("Edit the phone number of this user.")
    )
  end

  defp apply_action(socket, :delete_phone, _actor) do
    assign(socket,
      page_title: gettext("Are you sure?"),
      page_subtitle: gettext("Are you sure you want to delete this phone? This action cannot be undone.")
    )
  end

  defp assign_emails(socket, %Actor{} = actor) do
    assign(socket, emails: actor.emails)
  end

  defp assign_phones(socket, %Actor{} = actor) do
    assign(socket, phones: actor.phones)
  end

  defp assign_identities(socket, %Actor{} = actor) do
    assign(socket, identities: actor.identities)
  end

  defp save_actor(socket, actor_params) do
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
         |> assign_form(changeset)
         |> put_toast(:info, "User saved.", title: gettext("Success"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp user_title(name) do
    if Util.present?(name), do: name, else: gettext("User")
  end
end
