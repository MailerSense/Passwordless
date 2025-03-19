defmodule PasswordlessWeb.Components.PageComponents do
  @moduledoc false
  use Phoenix.Component

  import PasswordlessWeb.Components.Container
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
    <div class={["pc-page-header", @class]}>
      <%= if @inner_block do %>
        {render_slot(@inner_block)}
      <% end %>
    </div>
    """
  end

  @doc """
  Allows you to have a heading on the left side, and some action buttons on the right (default slot)
  """

  attr :class, :string, default: ""
  attr :field, Phoenix.HTML.FormField, required: true
  slot :inner_block

  def subpage_header(assigns) do
    ~H"""
    <div class={["pc-page-header", @class]}>
      <div class="relative">
        <.field type="editor" field={@field} />
        <div class="pc-editor-field-icon">
          <.icon name="remix-pencil-line" class="pc-editor-field-icon__icon" />
        </div>
      </div>

      <%= if @inner_block do %>
        {render_slot(@inner_block)}
      <% end %>
    </div>
    """
  end

  @doc "Gives you a white background with shadow."
  attr :class, :any, default: nil
  attr :padded, :boolean, default: false
  attr :shadow_class, :string, default: "shadow-1"
  attr :rest, :global
  slot :inner_block

  def box(assigns) do
    ~H"""
    <section
      {@rest}
      class={[
        "pc-box",
        @class,
        @shadow_class,
        if(@padded, do: "p-6", else: "")
      ]}
    >
      {render_slot(@inner_block)}
    </section>
    """
  end

  @doc "Gives you a white background with shadow."
  attr :class, :string, default: ""
  attr :pad_top, :boolean, default: true
  attr :padded, :boolean, default: true
  attr :container, :boolean, default: false
  attr :color_class, :string, default: "bg-white"
  attr :rest, :global
  slot :inner_block
  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]

  def area(assigns) do
    ~H"""
    <section
      {@rest}
      class={[
        "bg-slate-900 md:px-6 lg:px-10 pb-8 md:pb-10",
        if(@pad_top, do: "pt-10")
      ]}
    >
      <%= if @container do %>
        <div class="w-full bg-white rounded-3xl">
          <.container max_width={@max_width} class={@class}>
            {render_slot(@inner_block)}
          </.container>
        </div>
      <% else %>
        <div class={[
          "rounded-3xl",
          @color_class,
          if(@container, do: "px-[156px]"),
          if(@padded, do: "p-10"),
          @class
        ]}>
          {render_slot(@inner_block)}
        </div>
      <% end %>
    </section>
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
      <.icon name={@icon} class={["w-6 h-6", menu_item_icon_classes(@is_active?)]} />
      {@label}
    </.a>
    """
  end

  # Private

  defp menu_item_classes(true), do: "pc-sidebar__menu-item--active"
  defp menu_item_classes(false), do: "pc-sidebar__menu-item--inactive"
  defp menu_item_icon_classes(true), do: "pc-sidebar__menu-item-icon--active"
  defp menu_item_icon_classes(false), do: "pc-sidebar__menu-item-icon--inactive"
end
