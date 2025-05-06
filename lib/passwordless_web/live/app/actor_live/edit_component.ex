defmodule PasswordlessWeb.App.ActorLive.EditComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Locale
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: Action,
    count: 0,
    default_limit: 25,
    default_order: %{
      order_by: [:id],
      order_directions: [:desc]
    }
  ]

  @impl true
  def update(%{current_app: %App{} = app, actor: %Actor{} = actor} = assigns, socket) do
    states = Enum.map(Actor.states(), fn state -> {Phoenix.Naming.humanize(state), state} end)
    changeset = Passwordless.change_actor(app, actor)
    languages = Enum.map(Actor.languages(), fn code -> {Keyword.fetch!(Locale.languages(), code), code} end)

    icon_mapping = fn
      nil -> "remix-checkbox-circle-fill"
      "active" -> "remix-checkbox-circle-fill"
      :active -> "remix-checkbox-circle-fill"
      "locked" -> "remix-close-circle-fill"
      :locked -> "remix-close-circle-fill"
    end

    flag_mapping = fn
      nil -> "flag-gb"
      "en" -> "flag-gb"
      :en -> "flag-gb"
      code -> "flag-#{code}"
    end

    socket =
      socket
      |> assign(assigns)
      |> assign(
        states: states,
        languages: languages,
        icon_mapping: icon_mapping,
        flag_mapping: flag_mapping,
        property_editor: false
      )
      |> assign_form(changeset)
      |> assign_emails(actor)
      |> assign_actions()

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_property_editor", _params, socket) do
    {:noreply, update(socket, :property_editor, &Kernel.not/1)}
  end

  @impl true
  def handle_event("save", %{"actor" => actor_params}, socket) do
    save_actor(socket, actor_params)
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
  def handle_event("load_more", _params, socket) do
    if socket.assigns[:finished] do
      {:noreply, socket}
    else
      query = action_query(socket.assigns.current_app, socket.assigns.actor)
      assigns = Map.take(socket.assigns, ~w(cursor)a)

      {:noreply,
       socket
       |> assign(finished: false)
       |> start_async(:load_actions, fn -> load_actions(query, assigns) end)}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_actions, {:ok, %{actions: actions, meta: meta, cursor: cursor}}, socket) do
    socket = assign(socket, meta: meta, cursor: cursor, finished: Enum.empty?(actions))
    socket = stream(socket, :actions, actions)

    {:noreply, socket}
  end

  @impl true
  def handle_async(_event, _reply, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(user_name: Ecto.Changeset.get_field(changeset, :name))
    |> assign(user_state: Ecto.Changeset.get_field(changeset, :state))
    |> assign(user_active: Ecto.Changeset.get_field(changeset, :state) == :active)
    |> assign(user_properties: Ecto.Changeset.get_field(changeset, :properties))
  end

  defp assign_emails(socket, %Actor{} = actor) do
    assign(socket, emails: actor.emails)
  end

  defp action_query(%App{} = app, %Actor{} = actor) do
    app
    |> Action.get_by_actor(actor)
    |> Action.preload_events()
  end

  defp load_actions(query, %{cursor: cursor}) do
    filters = %{"first" => 25, "after" => cursor}
    {actions, meta} = DataTable.search(query, filters, @data_table_opts)

    cursor =
      case List.last(actions) do
        %Action{} = action -> Flop.Cursor.encode(%{id: action.id})
        _ -> nil
      end

    %{actions: actions, meta: meta, cursor: cursor}
  end

  defp assign_actions(socket) do
    query = action_query(socket.assigns.current_app, socket.assigns.actor)
    params = %{}
    {actions, meta} = DataTable.search(query, params, @data_table_opts)

    cursor =
      case List.last(actions) do
        %Action{} = action -> Flop.Cursor.encode(%{id: action.id})
        _ -> nil
      end

    socket
    |> assign(
      meta: meta,
      cursor: cursor,
      finished: false
    )
    |> stream(:actions, actions, reset: true)
  end

  defp save_actor(socket, actor_params) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.update_actor(app, actor, actor_params) do
      {:ok, _actor} ->
        {:noreply,
         socket
         |> put_toast(:info, "User saved.", title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp translate_authenticator(:sms_otp), do: gettext("SMS OTP")
  defp translate_authenticator(:whatsapp_otp), do: gettext("WhatsApp OTP")
  defp translate_authenticator(:email_otp), do: gettext("Email OTP")
  defp translate_authenticator(:magic_link), do: gettext("Magic link")
end
