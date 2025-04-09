defmodule PasswordlessWeb.Components.Dropdown do
  @moduledoc false
  use Phoenix.Component

  import PasswordlessWeb.Components.Icon

  alias PasswordlessWeb.Components.Link
  alias Phoenix.LiveView.JS

  @transition_in_base "transition transform ease-out duration-100"
  @transition_in_start "transform opacity-0 scale-95"
  @transition_in_end "transform opacity-100 scale-100"

  @transition_out_base "transition ease-in duration-75"
  @transition_out_start "transform opacity-100 scale-100"
  @transition_out_end "transform opacity-0 scale-95"

  attr :options_container_id, :string
  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"]
  attr :label, :string, default: nil, doc: "labels your dropdown option"
  attr :label_icon, :string, default: nil, doc: "labels your dropdown option"
  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :variant, :string, default: "solid", values: ["solid", "outline"]

  attr :menu_items_wrapper_class, :string,
    default: "",
    doc: "any extra CSS class for menu item wrapper container"

  attr :js_lib, :string,
    default: "live_view_js",
    values: ["live_view_js"],
    doc: "javascript library used for toggling"

  attr :placement, :string, default: "left", values: ["left", "right", "center"]
  attr :rest, :global

  slot :trigger_element
  slot :inner_block, required: false

  @doc """
    <.dropdown label="Dropdown" js_lib="alpine_js|live_view_js">
      <.dropdown_menu_item link_type="button">
        Button item with icon
      </.dropdown_menu_item>
      <.dropdown_menu_item link_type="a" to="/" label="a item" />
      <.dropdown_menu_item link_type="a" to="/" disabled label="disabled item" />
      <.dropdown_menu_item link_type="live_patch" to="/" label="Live Patch item" />
      <.dropdown_menu_item link_type="live_redirect" to="/" label="Live Redirect item" />
    </.dropdown>
  """
  def dropdown(assigns) do
    assigns =
      assign_new(assigns, :options_container_id, fn -> Util.id("dropdown") end)

    ~H"""
    <div
      {@rest}
      {js_attributes("container", @js_lib, @options_container_id)}
      class={[@class, "pc-dropdown"]}
    >
      <%= if @trigger_element && Util.blank?(@label) do %>
        <button
          type="button"
          aria-haspopup="true"
          {js_attributes("button", @js_lib, @options_container_id)}
        >
          <span class="sr-only">Open</span>
          {render_slot(@trigger_element)}
        </button>
      <% else %>
        <button
          type="button"
          class={trigger_button_classes(@label, @trigger_element, @size, @variant)}
          aria-haspopup="true"
          {js_attributes("button", @js_lib, @options_container_id)}
        >
          <span class="sr-only">Open</span>
          <.icon :if={@label_icon} name={@label_icon} class="pc-dropdown__icon" />
          <span>{@label}</span>
          <.icon name="remix-arrow-down-s-line" class="pc-dropdown__chevron" />
        </button>
      <% end %>
      <div
        id={@options_container_id}
        role="menu"
        class={[
          size_class(@size),
          placement_class(@placement),
          @menu_items_wrapper_class,
          "pc-dropdown__menu-items-wrapper"
        ]}
        aria-orientation="vertical"
        aria-labelledby="options-menu"
        {js_attributes("options_container", @js_lib, @options_container_id)}
      >
        <nav role="none">
          {render_slot(@inner_block)}
        </nav>
      </div>
    </div>
    """
  end

  attr :to, :string, default: nil, doc: "link path"
  attr :label, :string, doc: "link label"
  attr :class, :string, default: "", doc: "any additional CSS classes"
  attr :disabled, :boolean, default: false

  attr :link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type)
  slot :inner_block, required: false

  def dropdown_menu_item(assigns) do
    ~H"""
    <Link.a
      to={@to}
      class={[@class, "pc-dropdown__menu-item", get_disabled_classes(@disabled)]}
      disabled={@disabled}
      link_type={@link_type}
      {@rest}
    >
      {render_slot(@inner_block) || @label}
    </Link.a>
    """
  end

  def dropdown_separator(assigns) do
    ~H"""
    <hr class="pc-dropdown__separator" />
    """
  end

  # Private

  defp trigger_button_classes(nil, [], size, variant), do: "pc-dropdown__trigger-button--no-label--#{size}-#{variant}"

  defp trigger_button_classes(_label, [], size, variant),
    do: "pc-dropdown__trigger-button--with-label--#{size}-#{variant}"

  defp trigger_button_classes(_label, _trigger_element, size, variant),
    do: "pc-dropdown__trigger-button--with-label-and-trigger-element--#{size}-#{variant}"

  defp js_attributes("container", "live_view_js", options_container_id) do
    %{
      "phx-click-away":
        JS.hide(
          to: "##{options_container_id}",
          transition: {@transition_out_base, @transition_out_start, @transition_out_end}
        )
    }
  end

  defp js_attributes("button", "live_view_js", options_container_id) do
    %{
      "phx-click":
        JS.toggle(
          to: "##{options_container_id}",
          display: "block",
          in: {@transition_in_base, @transition_in_start, @transition_in_end},
          out: {@transition_out_base, @transition_out_start, @transition_out_end}
        )
    }
  end

  defp js_attributes("options_container", "live_view_js", _options_container_id) do
    %{
      style: "display: none;"
    }
  end

  defp size_class(size), do: "pc-dropdown__menu-items-wrapper-size--#{size}"

  defp placement_class("left"), do: "pc-dropdown__menu-items-wrapper-placement--left"
  defp placement_class("right"), do: "pc-dropdown__menu-items-wrapper-placement--right"
  defp placement_class("center"), do: "pc-dropdown__menu-items-wrapper-placement--center"

  defp get_disabled_classes(true), do: "pc-dropdown__menu-item--disabled"
  defp get_disabled_classes(false), do: ""
end
