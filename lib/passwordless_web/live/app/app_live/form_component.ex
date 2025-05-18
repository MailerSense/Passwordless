defmodule PasswordlessWeb.App.AppLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.FileUploads

  @impl true
  def update(%{app: app} = assigns, socket) do
    changeset = Passwordless.change_app(app)

    upload_opts =
      FileUploads.prepare(
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 5_242_880 * 2
      )

    {:ok,
     socket
     |> assign(assigns)
     |> assign(uploaded_files: [])
     |> assign_form(changeset)
     |> allow_upload(:logo, upload_opts)}
  end

  @impl true
  def handle_event("validate", %{"new_app" => app_params}, socket) do
    app_name = get_in(app_params, ["name"])

    app_params =
      app_params
      |> put_in(["settings", "display_name"], app_name)
      |> put_in(["settings", "allowlisted_ip_addresses"], [%{address: "0.0.0.0/0"}])

    changeset =
      socket.assigns.app
      |> Passwordless.change_app(app_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"new_app" => app_params}, socket) do
    app_params = maybe_add_logo(app_params, socket)
    save_app(socket, app_params)
  end

  @impl true
  def handle_event("clear_logo", _params, socket) do
    save_app(socket, %{logo: nil})
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :logo, ref)}
  end

  # Private

  defp maybe_add_logo(user_params, socket) do
    uploaded_files = FileUploads.consume_uploaded_entries(socket, :logo)

    case uploaded_files do
      [{path, _entry} | _] ->
        Map.put(user_params, "logo", path)

      [] ->
        user_params
    end
  end

  defp save_app(socket, app_params) do
    app_name = get_in(app_params, ["name"])

    app_params =
      app_params
      |> put_in(["settings", "display_name"], app_name)
      |> put_in(["settings", "allowlisted_ip_addresses"], [%{address: "0.0.0.0/0"}])

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
    settings = Ecto.Changeset.get_field(changeset, :settings)

    socket
    |> assign(form: to_form(changeset, as: :new_app))
    |> assign(logo_src: settings.logo)
  end
end
