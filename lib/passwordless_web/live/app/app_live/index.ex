defmodule PasswordlessWeb.App.AppLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.Accounts.User

  @upload_provider :passwordless |> Application.compile_env!(:media_upload) |> Keyword.fetch!(:adapter)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    upload_opts = [
      accept: ~w(.jpg .jpeg .png .svg .webp),
      max_entries: 1,
      max_file_size: 5_242_880 * 2
    ]

    upload_opts =
      if Passwordless.config(:env) == :prod do
        Keyword.put(upload_opts, :external, &@upload_provider.presign_upload/2)
      else
        upload_opts
      end

    {:noreply,
     socket
     |> assign(uploaded_files: [])
     |> apply_action(socket.assigns.live_action, params)
     |> assign_form(Passwordless.change_app(socket.assigns.current_app))
     |> allow_upload(:logo, upload_opts)}
  end

  @impl true
  def handle_event("delete_app", _params, socket) do
    case Passwordless.delete_app(socket.assigns.current_app) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("App deleted successfully."))
         |> push_navigate(to: ~p"/app")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Failed to delete app!"), title: gettext("Error"))
         |> push_patch(to: ~p"/app")}
    end
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app")}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app")}
  end

  @impl true
  def handle_event("validate", %{"app" => app_params}, socket) do
    changeset =
      socket.assigns.current_app
      |> Passwordless.change_app(app_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"app" => app_params}, socket) do
    app_params = maybe_add_logo(app_params, socket)
    save_app(socket, app_params)
  end

  @impl true
  def handle_event("clear_logo", _params, socket) do
    save_app(socket, %{logo: nil})
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :logo, ref)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index, _params) do
    assign(socket,
      page_title: gettext("App")
    )
  end

  defp apply_action(socket, :new, _params) do
    assign(socket,
      page_title: gettext("Create app"),
      page_subtitle:
        gettext(
          "App is a container for your users, authentication methods and other data. Create one app per project or environment."
        )
    )
  end

  defp apply_action(socket, :delete, _params) do
    assign(socket,
      page_title: gettext("Are you sure?"),
      page_subtitle: gettext("Are you sure you want to delete this app?")
    )
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp maybe_add_logo(user_params, socket) do
    uploaded_files = @upload_provider.consume_uploaded_entries(socket, :logo)

    if length(uploaded_files) > 0 do
      Map.put(user_params, "logo", hd(uploaded_files))
    else
      user_params
    end
  end

  defp save_app(socket, app_params) do
    case Passwordless.update_app(socket.assigns.current_app, app_params) do
      {:ok, app} ->
        socket =
          socket
          |> put_toast(:info, gettext("App settings have been saved."), title: gettext("Success"))
          |> assign(current_app: app)
          |> assign(current_user: %User{socket.assigns.current_user | current_app: app})
          |> assign_form(Passwordless.change_app(app))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
end
