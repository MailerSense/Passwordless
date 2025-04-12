defmodule PasswordlessWeb.App.EmailLive.FileComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  # Private

  defp new_file_input(assigns) do
    ~H"""
    <div class="p-3 rounded-lg items-center gap-3 xl:gap-6 inline-flex hover:bg-gray-100 dark:hover:bg-gray-700">
      <div class="p-2 xl:p-5 rounded-lg border-2 border-primary-200 dark:border-primary-600 justify-center items-center flex">
        <.icon name="remix-add-line" class="w-8 h-8 text-primary-600 flex-shrink-0" />
      </div>
      <div class="flex-col justify-start items-start gap-1 inline-flex">
        <div class="text-primary-500 dark:text-primary-600 text-base font-semibold line-clamp-1">
          Upload a new file
        </div>
        <div class="text-gray-600 dark:text-gray-300 text-sm font-medium leading-tight line-clamp-1">
          10 Mb max.
        </div>
      </div>
    </div>
    """
  end

  attr :file_name, :string, required: true, doc: "any extra CSS class for the parent container"
  attr :file_size, :integer, required: true, doc: "any extra CSS class for the parent container"

  attr :file_uploaded_at, DateTime,
    required: true,
    doc: "any extra CSS class for the parent container"

  defp file_card(assigns) do
    ~H"""
    <div class="p-3 rounded-lg items-center gap-3 xl:gap-6 inline-flex hover:bg-gray-100 dark:hover:bg-gray-700 group">
      <img
        class="size-[50px] xl:size-[76px] rounded-lg flex-shrink-0"
        src="https://picsum.photos/124/124"
      />
      <div class="flex-col justify-start items-start gap-1 inline-flex grow">
        <span class="text-gray-900 dark:text-white text-base font-semibold line-clamp-1">
          {@file_name}
        </span>
        <span class="text-gray-600 dark:text-gray-300 text-sm font-medium leading-tight line-clamp-1">
          {Sizeable.filesize(@file_size)}, {format_date(@file_uploaded_at)}
        </span>
      </div>
      <div class="flex items-center gap-3">
        <.icon_button
          size="sm"
          icon="remix-file-copy-line"
          class="invisible group-hover:visible"
          color="light"
          title={gettext("Copy")}
          variant="outline"
        />
        <.icon_button
          size="sm"
          icon="remix-delete-bin-line"
          class="invisible group-hover:visible"
          color="danger"
          title={gettext("Delete")}
          variant="outline"
        />
      </div>
    </div>
    """
  end
end
