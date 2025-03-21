defmodule PasswordlessWeb.Components.Alert do
  @moduledoc false
  use Phoenix.Component

  alias PasswordlessWeb.Components.Icon

  attr(:color, :string,
    default: "info",
    values: ["info", "success", "warning", "danger"]
  )

  attr(:with_icon, :boolean, default: false, doc: "adds some icon base classes")
  attr(:override, :boolean, default: false, doc: "adds some icon base classes")
  attr(:class, :any, default: "", doc: "CSS class for parent div")
  attr(:heading, :string, default: nil, doc: "label your heading")
  attr(:label, :string, default: nil, doc: "label your alert")
  attr(:rest, :global)

  attr(:close_button_properties, :list,
    default: nil,
    doc: "a list of properties passed to the close button"
  )

  slot(:inner_block)
  slot(:action, required: false)

  def alert(assigns) do
    assigns = assign(assigns, :classes, alert_classes(assigns))

    ~H"""
    <div {@rest} class={@classes}>
      <%= if @with_icon do %>
        <.get_icon color={@color} />
      <% end %>

      <div class="pc-alert">
        <div class="pc-alert__inner">
          <div class="pc-alert__label">
            {render_slot(@inner_block) || @label}
          </div>

          <%= if Util.present?(@action) do %>
            {render_slot(@action)}
          <% end %>

          <%= if @close_button_properties do %>
            <button
              class={["pc-alert__dismiss-button", get_dismiss_icon_classes(@color)]}
              {@close_button_properties}
            >
              <Icon.icon name="remix-close-line" class="self-start w-4 h-4" />
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Private

  defp alert_classes(opts) do
    opts = %{
      color: opts[:color] || "info",
      class: opts[:class] || "",
      override: opts[:override] || false
    }

    base_classes = "pc-alert-base-classes"
    color_css = get_color_classes(opts.color)
    custom_classes = opts.class

    [unless(opts[:override], do: base_classes), color_css, custom_classes]
  end

  defp get_color_classes("info"), do: "pc-alert--info"

  defp get_color_classes("success"), do: "pc-alert--success"

  defp get_color_classes("warning"), do: "pc-alert--warning"

  defp get_color_classes("danger"), do: "pc-alert--danger"

  defp get_dismiss_icon_classes("info"), do: "pc-alert__dismiss-button--info"

  defp get_dismiss_icon_classes("success"), do: "pc-alert__dismiss-button--success"

  defp get_dismiss_icon_classes("warning"), do: "pc-alert__dismiss-button--warning"

  defp get_dismiss_icon_classes("danger"), do: "pc-alert__dismiss-button--danger"

  defp get_icon(%{color: "info"} = assigns) do
    ~H"""
    <Icon.icon name="remix-information-fill" class="w-6 h-6 text-info-400 dark:text-info-500" />
    """
  end

  defp get_icon(%{color: "success"} = assigns) do
    ~H"""
    <Icon.icon
      name="remix-checkbox-circle-fill"
      class="w-6 h-6 text-success-400 dark:text-success-500"
    />
    """
  end

  defp get_icon(%{color: "warning"} = assigns) do
    ~H"""
    <Icon.icon name="remix-alert-fill" class="w-6 h-6 text-warning-400 dark:text-warning-500" />
    """
  end

  defp get_icon(%{color: "danger"} = assigns) do
    ~H"""
    <Icon.icon name="remix-close-circle-fill" class="w-6 h-6 text-danger-400 dark:text-danger-500" />
    """
  end
end
