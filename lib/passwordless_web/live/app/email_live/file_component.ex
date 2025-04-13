defmodule PasswordlessWeb.App.EmailLive.FileComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.FileUploads
  alias Passwordless.Media

  @impl true
  def update(%{current_app: %App{} = app} = assigns, socket) do
    media = Enum.reject([logo_to_media(app) | Passwordless.list_media(app)], &is_nil/1)

    changeset =
      app
      |> Ecto.build_assoc(:media)
      |> Passwordless.change_media()

    upload_opts =
      FileUploads.prepare(
        accept: ~w(.jpg .jpeg .png .svg .webp),
        max_entries: 1,
        max_file_size: 5_242_880 * 2
      )

    {:ok,
     socket
     |> assign(assigns)
     |> assign(media: media, uploaded_files: [])
     |> assign_form(changeset)
     |> allow_upload(:new_media, upload_opts)}
  end

  @impl true
  def handle_event("validate", %{"media" => media_params}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{}, socket) do
    media_params = maybe_add_media(%{}, socket)
    save_media(socket, media_params)
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :new_media, ref)}
  end

  @impl true
  def handle_event("delete_file", %{"id" => id}, socket) do
    media = Passwordless.get_media!(socket.assigns.current_app, id)

    case Passwordless.delete_media(media) do
      {:ok, _media} ->
        {:ok,
         socket
         |> put_toast(
           :info,
           gettext("File deleted."),
           title: gettext("Success")
         )
         |> push_patch(
           to: ~p"/emails/#{socket.assigns.template}/#{socket.assigns.language}/#{socket.assigns.live_action}"
         )}

      {:error, _} ->
        {:ok,
         socket
         |> put_toast(
           :info,
           gettext("Failed to delete file."),
           title: gettext("Error")
         )
         |> push_patch(
           to: ~p"/emails/#{socket.assigns.template}/#{socket.assigns.language}/#{socket.assigns.live_action}"
         )}
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
    |> assign(public_url: Ecto.Changeset.get_field(changeset, :public_url))
  end

  defp maybe_add_media(media_params, socket) do
    uploaded_files = FileUploads.consume_uploaded_entries(socket, :new_media)

    case uploaded_files do
      [
        {path,
         %Phoenix.LiveView.UploadEntry{
           client_name: client_name,
           client_size: client_size
         }}
        | _
      ] ->
        media_params
        |> Map.put("public_url", path)
        |> Map.put("name", client_name)
        |> Map.put("size", client_size)

      [] ->
        media_params
    end
  end

  defp logo_to_media(%App{logo: nil}), do: nil

  defp logo_to_media(%App{logo: logo} = app) do
    %Media{
      name: Path.basename(logo),
      size: 1000,
      mime: MIME.from_path(logo),
      public_url: logo,
      inserted_at: app.inserted_at,
      updated_at: app.updated_at,
      app_id: app.id
    }
  end

  defp save_media(socket, media_params) do
    app = socket.assigns.current_app

    case Passwordless.create_media(app, media_params) do
      {:ok, media} ->
        {:ok,
         socket
         |> put_toast(
           :info,
           gettext("File uploaded."),
           title: gettext("Success")
         )
         |> push_patch(
           to: ~p"/emails/#{socket.assigns.template}/#{socket.assigns.language}/#{socket.assigns.live_action}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  attr :id, :string, default: nil, doc: "param"
  attr :name, :string, required: true, doc: "param"
  attr :size, :integer, required: true, doc: "param"
  attr :mime, :string, required: true, doc: "param"
  attr :public_url, :string, required: true, doc: "param"
  attr :updated_at, DateTime, required: true, doc: "param"
  attr :target, :map, required: true, doc: "param"

  defp file_card(assigns) do
    ~H"""
    <div class="p-3 rounded-lg flex items-center justify-between hover:bg-gray-100 dark:hover:bg-gray-700 group">
      <div class="flex items-center gap-6">
        <img class="size-[50px] xl:size-[76px] rounded-lg flex-shrink-0" src={@public_url} />
        <div class="flex-col justify-start items-start gap-1 inline-flex grow">
          <span class="text-gray-900 dark:text-white text-base font-semibold line-clamp-1 break-all">
            {@name}
          </span>
          <span class="text-gray-600 dark:text-gray-300 text-sm font-medium leading-tight line-clamp-1">
            {Sizeable.filesize(@size)}, {format_date(@updated_at)}
          </span>
        </div>
      </div>
      <div class="flex items-center gap-3">
        <.icon_button
          size="sm"
          icon="remix-file-copy-line"
          class="invisible group-hover:visible"
          color="light"
          title={gettext("Copy")}
          variant="outline"
          phx-click="copy_file"
          phx-value-url={@public_url}
          phx-target={@target}
        />
        <.icon_button
          :if={Util.present?(@id)}
          size="sm"
          icon="remix-delete-bin-line"
          class="invisible group-hover:visible"
          color="danger"
          title={gettext("Delete")}
          variant="outline"
          phx-click="delete_file"
          phx-value-id={@id}
          phx-target={@target}
          data-confirm={gettext("Are you sure you want to delete this file?")}
        />
      </div>
    </div>
    """
  end
end
