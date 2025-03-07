defmodule PasswordlessWeb.Components.PageComponents do
  @moduledoc false
  use Phoenix.Component

  import PasswordlessWeb.Components.Container
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
      <h1 class="pc-page-header--text">
        {@title}
      </h1>
      <%= if @inner_block do %>
        {render_slot(@inner_block)}
      <% end %>
    </div>
    """
  end

  @doc "Gives you a white background with shadow."
  attr :class, :any, default: nil
  attr :padded, :boolean, default: false
  attr :shadow_class, :string, default: "shadow-2"
  attr :rest, :global
  slot :inner_block

  def box(assigns) do
    ~H"""
    <section
      {@rest}
      class={[
        "pc-box",
        @shadow_class,
        @class,
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

  @doc """
  Provides a container with a sidebar on the left and main content on the right. Useful for things like user settings.

  ---------------------------------
  | Sidebar | Main                |
  |         |                     |
  |         |                     |
  |         |                     |
  ---------------------------------
  """

  attr :current_page, :atom

  attr :menu_items, :list,
    required: true,
    doc: "list of maps with keys :name, :path, :label, :icon (atom)"

  slot(:inner_block)

  def sidebar_tabs_container(assigns) do
    ~H"""
    <.box class="flex flex-col border border-slate-200 divide-y divide-slate-200 dark:border-none dark:divide-slate-700 md:divide-y-0 md:divide-x md:flex-row">
      <div class="flex-shrink-0 py-6 md:w-72">
        <.sidebar_menu_item :for={menu_item <- @menu_items} current={@current_page} {menu_item} />
      </div>

      <div class="flex-grow px-4 py-6 sm:p-6 lg:pb-8">
        {render_slot(@inner_block)}
      </div>
    </.box>
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
        "pc-sidebar__menu-item",
        menu_item_classes(@is_active?)
      ]}
    >
      <.icon name={@icon} class={["w-6 h-6", menu_item_icon_classes(@is_active?)]} />
      {@label}
    </.a>
    """
  end

  defp menu_item_classes(true), do: "pc-sidebar__menu-item--active"
  defp menu_item_classes(false), do: "pc-sidebar__menu-item--inactive"
  defp menu_item_icon_classes(true), do: "pc-sidebar__menu-item-icon--active"
  defp menu_item_icon_classes(false), do: "pc-sidebar__menu-item-icon--inactive"
end
