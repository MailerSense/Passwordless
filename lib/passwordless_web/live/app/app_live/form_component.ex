defmodule PasswordlessWeb.App.AppLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  @upload_provider Passwordless.FileUploads.Local

  @impl true
  def update(%{app: app} = assigns, socket) do
    changeset = Passwordless.change_app(app)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(uploaded_files: [])
     |> assign_form(changeset)
     |> allow_upload(:logo,
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
    app_params = maybe_add_logo(app_params, socket)
    save_app(socket, app_params)
  end

  @impl true
  def handle_event("clear_logo", _params, socket) do
    save_app(socket, %{logo: nil})
  end

  # Private

  defp maybe_add_logo(user_params, socket) do
    uploaded_files = @upload_provider.consume_uploaded_entries(socket, :logo)

    if length(uploaded_files) > 0 do
      Map.put(user_params, "logo", hd(uploaded_files))
    else
      user_params
    end
  end

  defp save_app(socket, app_params) do
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
    socket
    |> assign(form: to_form(changeset))
    |> assign(logo_src: Ecto.Changeset.get_field(changeset, :logo))
  end
end
