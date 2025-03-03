defmodule PasswordlessWeb.App.AppLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  @impl true
  def update(%{app: app} = assigns, socket) do
    changeset = Passwordless.change_app(app, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(uploaded_files: [])
     |> assign_form(changeset)
     |> allow_upload(:avatar,
       # SETUP_TODO: Uncomment the line below if using an external provider (Cloudinary or S3)
       # external: &@upload_provider.presign_upload/2,
       accept: ~w(.jpg .jpeg .png .svg .webp),
       max_entries: 1,
       max_file_size: 5_242_880 * 2
     )}
  end

  @impl true
  def handle_event("validate", %{"app" => app_params}, socket) do
    changeset =
      socket.assigns.app
      |> Passwordless.change_app(app_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"app" => app_params}, socket) do
    IO.inspect(socket.assigns.live_action)
    IO.inspect(app_params)
    save_app(socket, socket.assigns.live_action, app_params)
  end

  # Private

  defp save_app(socket, :edit, app_params) do
    case Passwordless.update_app(socket.assigns.app, app_params) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("App updated."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_app(socket, :new, app_params) do
    IO.inspect(app_params)

    case Passwordless.create_full_app(socket.assigns.current_org, app_params) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("App created."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end
