defmodule PasswordlessWeb.Components.Badge do
  @moduledoc false
  use Phoenix.Component

  import PasswordlessWeb.Components.Icon

  attr(:size, :string, default: "md", values: ["sm", "md", "lg"])

  attr(:color, :string,
    default: "primary",
    values: [
      "primary",
      "secondary",
      "light",
      "light-muted",
      "success",
      "danger",
      "info",
      "warning",
      "gray",
      "indigo",
      "purple",
      "fuchsia",
      "pink",
      "rose"
    ]
  )

  attr(:with_dot, :boolean, default: false, doc: "adds some dot base classes")
  attr(:with_icon, :boolean, default: false, doc: "adds some icon base classes")
  attr(:class, :string, default: "", doc: "CSS class for parent div")
  attr(:label, :string, default: nil, doc: "label your badge")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def badge(assigns) do
    ~H"""
    <badge
      {@rest}
      class={[
        "pc-badge",
        "pc-badge--#{@color}",
        "pc-badge--#{@size}",
        @with_dot && "pc-badge--with-dot",
        @with_icon && "pc-badge--with-icon",
        @class
      ]}
    >
      <span :if={@with_dot} class={["pc-badge__dot", "pc-badge__dot--#{@color}"]}></span>
      {render_slot(@inner_block) || @label}
    </badge>
    """
  end

  attr(:icon, :string, required: true)
  attr(:size, :string, default: "md", values: ["sm", "md", "lg"])

  attr(:color, :string,
    default: "success",
    values: [
      "success",
      "danger",
      "warning",
      "info",
      "fuchsia",
      "pink",
      "rose"
    ]
  )

  attr(:class, :string, default: "", doc: "CSS class for parent div")
  attr(:label, :string, default: nil, doc: "label your badge")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def icon_badge(assigns) do
    ~H"""
    <badge
      {@rest}
      class={[
        "pc-icon-badge",
        @class
      ]}
    >
      <.icon name={@icon} class={["pc-icon-badge__icon--#{@color}", "pc-icon-badge__icon--#{@size}"]} />
      <%= if @label do %>
        <span class={"pc-icon-badge__label--#{@size}"}>
          {@label}
        </span>
      <% end %>
    </badge>
    """
  end
end
