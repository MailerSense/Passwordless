defmodule PasswordlessWeb.App.UserLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Locale
  alias Passwordless.User

  @impl true
  def update(%{current_app: %App{} = app, user: %User{} = user} = assigns, socket) do
    changeset = Passwordless.change_user(app, user)
    languages = Enum.map(User.languages(), fn code -> {Keyword.fetch!(Locale.languages(), code), code} end)

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
  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.live_action, user_params)
  end

  # Private

  defp save_user(socket, :edit, user_params) do
    app = socket.assigns.current_app
    user = socket.assigns.user

    case Passwordless.update_user(app, user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("User has been updated."), title: gettext("Success"))
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Passwordless.create_user(socket.assigns.current_app, user_params) do
      {:ok, _user} ->
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
