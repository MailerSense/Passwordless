defmodule PasswordlessWeb.FileUploadComponents do
  @moduledoc false
  use PasswordlessWeb, :component
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Field
  import PasswordlessWeb.Components.Icon

  @doc """
  A file upload input. Shows the current image, a preview of the incoming image and a delete button.
  Designed for 1 image uploads.
  """

  attr :upload, :map, required: true
  attr :current_image_src, :string, default: nil
  attr :current_image_class, :string, default: "h-16 w-16 rounded-md"

  attr :new_image_class, :string, doc: "classes for the new image. Defaults to current_image_class"

  attr :automatic_help_text, :boolean, default: false
  attr :help_text, :string, default: nil
  attr :max_translation, :string, default: "max"
  attr :label, :string, default: "Image"
  attr :class, :string, default: nil

  attr :delete_button_class, :string,
    default:
      "rounded-full w-6 h-6 p-1 absolute bottom-[-10%] right-[-10%] bg-slate-700/70 text-white hover:bg-slate-700 dark:hover:bg-slate-500/50"

  attr :on_delete, :string,
    default: nil,
    doc: "live view event to trigger when the delete button is clicked"

  attr :confirm_delete_text, :string, default: "Are you sure you want to remove this image?"

  attr :placeholder_icon, :string,
    default: "remix-image-line",
    doc: "the icon inside the placeholder image. Defaults to :photo, but you could use :user for an avatar"

  slot :placeholder

  def image_input(assigns) do
    assigns = assign_new(assigns, :new_image_class, fn -> assigns.current_image_class end)

    ~H"""
    <div class={["mb-6", @class]} phx-drop-target={@upload.ref}>
      <.field_label for={@upload.ref}>{@label}</.field_label>

      <div class="flex flex-col gap-3 md:items-center md:flex-row">
        <div class="flex items-center gap-3">
          <div :if={@current_image_src} class="relative shrink-0">
            <img class={@current_image_class} src={@current_image_src} />

            <button
              :if={@current_image_src && @on_delete}
              type="button"
              class={@delete_button_class}
              phx-click={@on_delete}
              data-confirm={@confirm_delete_text}
            >
              <.icon name="remix-close-line" />
            </button>
          </div>

          <div :if={!@current_image_src && render_slot(@placeholder)} class="relative shrink-0">
            {render_slot(@placeholder)}
          </div>

          <.dummy_image
            :if={!@current_image_src && !render_slot(@placeholder)}
            class={["self-center", @current_image_class]}
            inner_icon={@placeholder_icon}
          />

          <%= if @upload.entries != [] do %>
            <.icon name="remix-arrow-right-line" class="w-5 h-5" />
            <%= for entry <- @upload.entries do %>
              <div class="relative shrink-0">
                <.live_img_preview entry={entry} class={@new_image_class} />
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  aria-label="cancel"
                  class={@delete_button_class}
                >
                  <.icon name="remix-close-line" />
                </button>
              </div>
            <% end %>
          <% end %>
        </div>

        <div>
          <.live_file_input
            upload={@upload}
            class="block w-full text-sm rounded text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100 dark:file:bg-slate-700 dark:file:text-slate-300 dark:hover:file:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 cursor-pointer"
          />

          <p :if={@automatic_help_text} class="pc-form-help-text line-clamp-1">
            {Enum.join(@upload.acceptable_exts, ", ")}
            <%= if @upload.max_file_size do %>
              ({@max_translation} {Sizeable.filesize(@upload.max_file_size)})
            <% end %>
          </p>

          <p :if={@help_text} class="pc-form-help-text">
            {@help_text}
          </p>

          <%= for entry <- @upload.entries do %>
            <%= for err <- upload_errors(@upload, entry) do %>
              <.field_error>{error_to_string(err)}</.field_error>
            <% end %>
          <% end %>
        </div>
      </div>

      <section>
        <%= for entry <- @upload.entries do %>
          <article class="hidden mt-2 justify-items-center phx-submit-loading:block">
            <div class="flex gap-2">
              <.progress color="primary" value={entry.progress} max={100} class="flex-grow mt-2" />

              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                aria-label="cancel"
              >
                &times;
              </button>
            </div>

            <p class="pc-form-help-text">
              {entry.client_name}
            </p>
          </article>
        <% end %>
      </section>
    </div>
    """
  end

  attr :class, :any, default: "h-20 w-20", doc: "classes for the image"
  attr :inner_icon_class, :string, default: "h-8 w-8", doc: "classes for the inner image icon"
  attr :inner_icon, :atom, default: :photo

  def dummy_image(assigns) do
    ~H"""
    <div class={[
      "flex items-center justify-center bg-slate-100 dark:bg-slate-700",
      @class
    ]}>
      <.icon name={@inner_icon} class={["text-slate-500 dark:text-slate-400", @inner_icon_class]} />
    </div>
    """
  end

  defp error_to_string(:too_large), do: gettext("File is too large")
  defp error_to_string(:not_accepted), do: gettext("You have selected an unacceptable file type")
  defp error_to_string(:too_many_files), do: gettext("You have selected too many files")
  defp error_to_string(error), do: error
end
