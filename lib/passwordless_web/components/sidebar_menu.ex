defmodule PasswordlessWeb.Components.SidebarMenu do
  @moduledoc """
  Functions concerned with rendering aspects of the sidebar layout.
  """

  use Phoenix.Component, global_prefixes: ~w(x-)

  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link

  attr :menu_items, :list, required: true
  attr :current_page, :atom, required: true
  attr :title, :string, default: nil
  attr :class, :any, default: nil

  def sidebar_menu(assigns) do
    ~H"""
    <%= if menu_items_grouped?(@menu_items) do %>
      <div class="flex flex-col gap-6">
        <.sidebar_menu_group
          :for={menu_group <- @menu_items}
          {menu_group}
          current_page={@current_page}
          class={[@class, "flex flex-col gap-6"]}
        />
      </div>
    <% else %>
      <.sidebar_menu_group title={@title} menu_items={@menu_items} current_page={@current_page} />
    <% end %>
    """
  end

  defp menu_items_grouped?(menu_items) do
    menu_items
    |> Enum.reject(fn menu_item -> Map.has_key?(menu_item, :custom_component) end)
    |> Enum.all?(fn menu_item ->
      Map.has_key?(menu_item, :title)
    end)
  end

  def sidebar_menu_group(%{custom_assigns: component_assigns, custom_component: component_func})
      when is_map(component_assigns) and is_function(component_func) do
    Phoenix.LiveView.TagEngine.component(
      component_func,
      component_assigns,
      {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
    )
  end

  def sidebar_menu_group(%{custom_assigns: lc_assigns, custom_component: lc} = assigns)
      when is_map(lc_assigns) and is_atom(lc) do
    ~H"""
    <.live_component module={@custom_component} {@custom_assigns} />
    """
  end

  def sidebar_menu_group(assigns), do: nav_menu_group(assigns)

  attr :current_page, :atom
  attr :menu_items, :list
  attr :title, :string

  def nav_menu_group(assigns) do
    ~H"""
    <nav>
      <p
        :if={Util.present?(@title)}
        class="px-4 mb-3 text-xs font-semibold text-slate-500 uppercase select-none"
        x-bind:class="isCollapsed ? 'hidden' : 'block'"
      >
        {@title}
      </p>

      <.sidebar_menu_item
        :for={menu_item <- @menu_items}
        all_menu_items={@menu_items}
        current_page={@current_page}
        {menu_item}
      />
    </nav>
    """
  end

  @doc """
  Renders a sidebar layout menu item using a custom component function, live component definition, or the default navigation item structure.
  """

  def sidebar_menu_item(%{custom_assigns: component_assigns, custom_component: component_func})
      when is_map(component_assigns) and is_function(component_func) do
    Phoenix.LiveView.TagEngine.component(
      component_func,
      component_assigns,
      {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
    )
  end

  def sidebar_menu_item(%{custom_assigns: lc_assigns, custom_component: lc} = assigns)
      when is_map(lc_assigns) and is_atom(lc) do
    ~H"""
    <.live_component module={@custom_component} {@custom_assigns} />
    """
  end

  def sidebar_menu_item(assigns), do: nav_menu_item(assigns)

  attr :current_page, :atom
  attr :path, :string, default: nil
  attr :icon, :any, default: nil
  attr :label, :string
  attr :name, :atom, default: nil
  attr :menu_items, :list, default: nil
  attr :all_menu_items, :list, default: nil
  attr :counters, :any, default: nil
  attr :patch_group, :atom, default: nil
  attr :link_type, :string, default: "live_redirect"

  def nav_menu_item(%{menu_items: nil} = assigns) do
    current_item = find_item(assigns.name, assigns.all_menu_items)
    assigns = assign(assigns, :current_item, current_item)

    ~H"""
    <.a
      id={"sidebar_menu_item_#{@label |> String.downcase() |> String.replace(" ", "_")}_anchor"}
      to={@path}
      link_type={
        if @current_item[:patch_group] &&
             @current_item[:patch_group] == @patch_group,
           do: "live_patch",
           else: "live_redirect"
      }
      class={["gap-4 w-full", menu_item_classes(@current_page, @name)]}
    >
      <.nav_menu_icon icon={@icon} />
      <span class="flex-1">
        {@label}
      </span>
      <div
        :if={@counters}
        class="flex ml-auto px-1.5 rounded-full justify-center items-center bg-slate-900 dark:bg-primary-300 text-white dark:text-slate-900 text-xs font-semibold leading-[18px]"
      >
        {elem(@counters, 0)}
      </div>
    </.a>
    """
  end

  def nav_menu_item(%{menu_items: _} = assigns) do
    ~H"""
    <div
      id={nav_menu_item_id(@label)}
      phx-update="ignore"
      class=""
      x-data={"{ open: #{if nav_menu_item_active?(@name, @current_page, @menu_items), do: "true", else: "false"} }"}
    >
      <button
        id={"#{nav_menu_item_id(@label)}_button"}
        type="button"
        phx-hook="TippyHook"
        data-tippy-content={@label}
        data-tippy-placement="top-end"
        x-bind:data-disable-tippy-on-mount="!isCollapsed"
        x-effect="isCollapsible && isCollapsed ? $el?._tippy?.enable() : $el?._tippy?.disable()"
        x-bind:class="isCollapsible && isCollapsed ? 'w-min gap-0' : 'w-full gap-3'"
        class={menu_item_classes(@current_page, @name)}
        @click.prevent="open = !open"
      >
        <.nav_menu_icon icon={@icon} />
        <%!-- hidden on collapse toggle --%>
        <div class="text-left" x-bind:class="isCollapsible && isCollapsed ? 'hidden' : 'flex-1'">
          {@label}
        </div>

        <%!-- Sub-menu expander --%>
        <div class="relative inline-block">
          <%!-- Chevron right --%>
          <div class="ml-2" x-bind:class="isCollapsed ? 'ml-0 absolute left-[6px] -top-1' : 'ml-2'">
            <.icon
              name="remix-arrow-right-s-line"
              class="transition duration-200 transform"
              x-bind:class="{ 'w-2 h-2': isCollapsed, 'w-3 h-3': !isCollapsed, 'rotate-90': open }"
            />
          </div>
        </div>
      </button>

      <%!-- Collapsed -- Sub-menu separator --%>
      <div
        x-show="isCollapsible && isCollapsed && open"
        class="h-[1px] bg-primary-700 dark:bg-primary-400 rounded-full w-2/4 my-2 mx-auto"
      >
      </div>

      <%!--
      Sub-menu Items
      Note: The collapsed view does accommodate nested items, but the current design is not final.
      Improving it to use pop-out menus when collapsed is planned.
      --%>
      <div
        class="mt-1 space-y-1"
        x-bind:class="isCollapsible && isCollapsed ? '' : 'ml-3'"
        x-show="open"
        x-cloak={!nav_menu_item_active?(@name, @current_page, @menu_items)}
      >
        <.sidebar_menu_item :for={menu_item <- @menu_items} current_page={@current_page} {menu_item} />
      </div>
    </div>
    """
  end

  defp nav_menu_item_id(label), do: "dropdown_#{label |> String.downcase() |> String.replace(" ", "_")}"

  attr :icon, :any, default: nil

  def nav_menu_icon(assigns) do
    ~H"""
    <.icon name={@icon} class={menu_icon_classes()} />
    """
  end

  # Check whether the current name equals the current page or whether any of the menu items have the current page as their name. A menu_item may have sub-items, so we need to check recursively.
  defp nav_menu_item_active?(name, current_page, menu_items) do
    name == current_page ||
      Enum.any?(menu_items, fn menu_item ->
        nav_menu_item_active?(menu_item[:name], current_page, menu_item[:menu_items] || [])
      end)
  end

  defp menu_icon_classes, do: "w-6 h-6"

  defp menu_item_base,
    do:
      "flex items-center text-base font-medium leading-normal px-4 py-3 transition duration-150 rounded-xl group select-none"

  # Active state
  defp menu_item_classes(page, page),
    do: "#{menu_item_base()} text-slate-900 dark:text-white bg-white dark:bg-slate-700 shadow-0"

  # Inactive state
  defp menu_item_classes(_current_page, _link_page),
    do:
      "#{menu_item_base()} text-slate-600 dark:text-slate-400 hover:text-slate-900 hover:bg-white dark:hover:bg-slate-700 dark:hover:text-white hover:shadow-0"

  defp find_item(name, menu_items) when is_list(menu_items) do
    Enum.find(menu_items, fn menu_item ->
      if menu_item[:name] == name do
        true
      else
        find_item(name, menu_item[:menu_items] || [])
      end
    end)
  end

  defp find_item(_, _), do: nil
end
