defmodule PasswordlessWeb.Components.PageComponents do
  @moduledoc false
  use Phoenix.Component

  import PasswordlessWeb.Components.Field
  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link

  @doc """
  Allows you to have a heading on the left side, and some action buttons on the right (default slot)
  """

  attr :class, :string, default: ""
  attr :title, :string, required: true
  slot :inner_block

  def page_header(assigns) do
    ~H"""
    <.div_wrapper class={["pc-page-header", @class]} wrap={Util.present?(@inner_block)}>
      <h1 class="pc-page-header--text">
        {@title}
      </h1>
      <%= if @inner_block do %>
        {render_slot(@inner_block)}
      <% end %>
    </.div_wrapper>
    """
  end

  @doc """
  Allows you to have a heading on the left side, and some action buttons on the right (default slot)
  """

  attr :class, :string, default: ""
  attr :field, Phoenix.HTML.FormField, required: true
  attr :rest, :global
  slot :inner_block
  slot :badge

  def subpage_header(assigns) do
    ~H"""
    <div class={["pc-page-header", @class]}>
      <.div_wrapper class="flex items-center gap-3" wrap={Util.present?(@badge)}>
        <div class="relative">
          <.field type="editor" field={@field} {@rest} />
          <div class="pc-editor-field-icon">
            <.icon name="remix-pencil-line" class="pc-editor-field-icon__icon" />
          </div>
        </div>
        {render_slot(@badge)}
      </.div_wrapper>

      <%= if @inner_block do %>
        {render_slot(@inner_block)}
      <% end %>
    </div>
    """
  end

  @doc "Gives you a white background with shadow."
  attr :class, :any, default: nil
  attr :card, :boolean, default: false
  attr :padded, :boolean, default: false
  attr :header, :string, default: nil
  attr :body_class, :any, default: nil
  attr :rest, :global
  slot :inner_block
  slot :actions

  def box(assigns) do
    ~H"""
    <section {@rest} class={["pc-box", @class]}>
      <.div_wrapper class="pc-box__header" wrap={Util.present?(@header)}>
        <h2 class={["text-lg font-semibold text-gray-900 dark:text-white"]}>
          {@header}
        </h2>
      </.div_wrapper>
      <div class={[if(@card, do: "pc-box__card"), if(@padded, do: "pc-box__padded"), @body_class]}>
        {render_slot(@inner_block)}
      </div>
      <.div_wrapper class="pc-box__actions" wrap={Util.present?(@actions)}>
        {render_slot(@actions)}
      </.div_wrapper>
    </section>
    """
  end

  @doc "Gives you a white background with shadow."
  attr :class, :string, default: ""
  attr :padded, :boolean, default: true
  attr :rest, :global
  slot :inner_block

  def area(assigns) do
    ~H"""
    <section
      {@rest}
      class={["bg-gray-200 dark:bg-gray-950/30 rounded-lg", if(@padded, do: "p-6"), @class]}
    >
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :class, :string, default: ""
  attr :title, :string, required: true
  attr :rest, :global
  slot :inner_block

  def area_header(assigns) do
    ~H"""
    <h3 class={["font-semibold text-gray-500 dark:text-gray-400 text-lg", @class]} {@rest}>
      {@title}
    </h3>
    """
  end

  attr :current, :atom
  attr :name, :string
  attr :path, :string
  attr :label, :string
  attr :icon, :atom

  def sidebar_menu_item(assigns) do
    assigns = assign(assigns, :is_active?, assigns.current == assigns.name)

    ~H"""
    <.a
      to={@path}
      title={@label}
      link_type="live_redirect"
      class={[
        "group",
        "pc-sidebar__menu-item group",
        menu_item_classes(@is_active?)
      ]}
    >
      <.icon
        :if={Util.present?(@icon)}
        name={@icon}
        class={["w-6 h-6", menu_item_icon_classes(@is_active?)]}
      />
      {@label}
    </.a>
    """
  end

  # Private

  defp menu_item_classes(true), do: "pc-sidebar__menu-item--active"
  defp menu_item_classes(false), do: "pc-sidebar__menu-item--inactive"
  defp menu_item_icon_classes(true), do: "pc-sidebar__menu-item-icon--active"
  defp menu_item_icon_classes(false), do: "pc-sidebar__menu-item-icon--inactive"

  attr :wrap, :boolean, default: false
  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp div_wrapper(assigns) do
    ~H"""
    <%= if @wrap do %>
      <div class={@class}>
        {render_slot(@inner_block)}
      </div>
    <% else %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end
end
