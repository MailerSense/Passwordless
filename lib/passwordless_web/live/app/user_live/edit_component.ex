defmodule PasswordlessWeb.App.UserLive.EditComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Action
  alias Passwordless.App
  alias Passwordless.Locale
  alias Passwordless.User
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
  def update(%{current_app: %App{} = app, user: %User{} = user} = assigns, socket) do
    changeset = Passwordless.change_user(app, user)
    languages = Enum.map(User.languages(), fn code -> {Keyword.fetch!(Locale.languages(), code), code} end)

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
        languages: languages,
        icon_mapping: icon_mapping,
        flag_mapping: flag_mapping,
        property_editor: false
      )
      |> assign_form(changeset)
      |> assign_emails(user)
      |> assign_actions()

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_property_editor", _params, socket) do
    {:noreply, update(socket, :property_editor, &Kernel.not/1)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, user_params)
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    app = socket.assigns.current_app
    user = socket.assigns.user

    changeset =
      app
      |> Passwordless.change_user(user, user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    if socket.assigns[:finished] do
      {:noreply, socket}
    else
      query = action_query(socket.assigns.current_app, socket.assigns.user)
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
    |> assign(user_data: Ecto.Changeset.get_field(changeset, :data))
  end

  defp assign_emails(socket, %User{} = user) do
    assign(socket, emails: user.emails)
  end

  defp action_query(%App{} = app, %User{} = user) do
    app
    |> Action.get_by_user(user)
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
    query = action_query(socket.assigns.current_app, socket.assigns.user)
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

  defp save_user(socket, user_params) do
    app = socket.assigns.current_app
    user = socket.assigns.user

    case Passwordless.update_user(app, user, user_params) do
      {:ok, _user} ->
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
