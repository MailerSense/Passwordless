defmodule PasswordlessWeb.App.AppLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(uploaded_files: [])
     |> apply_action(socket.assigns.live_action, params)
     |> assign_form(Passwordless.change_app(socket.assigns.current_app))
     |> allow_upload(:avatar,
       # SETUP_TODO: Uncomment the line below if using an external provider (Cloudinary or S3)
       # external: &@upload_provider.presign_upload/2,
       accept: ~w(.jpg .jpeg .png .svg .webp),
       max_entries: 1,
       max_file_size: 5_242_880 * 2
     )}
  end

  @impl true
  def handle_event("delete_app", _params, socket) do
    case Passwordless.delete_app(socket.assigns.current_app) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("App deleted successfully."))
         |> push_navigate(to: ~p"/app/app")}

      {:error, _} ->
        {:noreply,
         socket
         |> LiveToast.put_toast(:error, gettext("Failed to delete app!"))
         |> push_patch(to: ~p"/app/app")}
    end
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/app")}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/app")}
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
    case Passwordless.update_app(socket.assigns.current_app, app_params) do
      {:ok, app} ->
        socket =
          socket
          |> LiveToast.put_toast(:info, gettext("App updated."))
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
end
