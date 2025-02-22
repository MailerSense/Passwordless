defmodule PasswordlessWeb.Components.SidebarLayout do
  @moduledoc """
  A responsive layout with a left sidebar (main menu), as well as a drop down menu up the top right (user menu).

  Note that in order to utilise the collapsible sidebar feature, you must install the Alpine Persist plugin. See https://alpinejs.dev/plugins/persist for more information.
  """
  use Phoenix.Component, global_prefixes: ~w(x-)
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.SidebarMenu
  import PasswordlessWeb.Components.ThemeSwitch
  import PasswordlessWeb.Components.UsageBox
  import PasswordlessWeb.Components.UserTopbarMenu

  attr :collapsible, :boolean,
    default: false,
    doc:
      "The sidebar can be collapsed to display icon-only menu items. False by default. Requires the Alpine Persist plugin."

  attr :default_collapsed, :boolean,
    default: false,
    doc:
      "The sidebar will render as collapsed by default, if it is not already set in localStorage. False by default. Requires `:collapsible` to be true."

  attr :current_user, :map, default: nil

  attr :current_page, :atom,
    required: true,
    doc: "The current page. This will be used to highlight the current page in the menu."

  attr :current_section, :atom,
    required: true,
    doc: "The current section. This will be used to highlight the current section in the side menu."

  attr :current_subpage, :atom, default: nil

  attr :project_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the main menu in the sidebar."

  attr :org_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the main menu in the sidebar."

  attr :main_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the main menu in the sidebar."

  attr :user_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the user menu."

  attr :section_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the main menu in the sidebar."

  attr :sidebar_title, :string,
    default: nil,
    doc: "This will be displayed at the top of the sidebar."

  attr :home_path, :string,
    default: "/",
    doc: "The path to the home page. When a user clicks the logo, they will be taken to this path."

  attr :sidebar_lg_width_class, :string,
    default: "w-64",
    doc: "The width of the sidebar. Must have the lg: prefix."

  attr :sidebar_bg_class, :string, default: "bg-slate-100 dark:bg-slate-700/30"
  attr :sidebar_border_class, :string, default: "border-slate-200 dark:border-slate-700"
  attr :header_bg_class, :string, default: "bg-white dark:bg-slate-900"
  attr :header_border_class, :string, default: "border-slate-200 dark:border-slate-700"

  slot :inner_block, required: true, doc: "The main content of the page."

  slot :logo,
    doc: "Your logo. This will automatically sit within a link to the home_path attribute."

  slot :dropdown,
    doc: "Your logo. This will automatically sit within a link to the home_path attribute."

  attr :show_usage_box, :boolean,
    default: true,
    doc: "Whether to show the usage box."

  def sidebar_layout(assigns) do
    ~H"""
    <div
      class="flex h-screen overflow-hidden bg-white dark:bg-slate-800"
      x-data={"{sidebarOpen: $persist(true), isCollapsible: #{@collapsible}, #{x_persist_collapsed(assigns)}}"}
    >
      <div class={["relative z-40"]} x-show="sidebarOpen">
        <aside
          id="sidebar"
          role="navigation"
          class={[
            "z-40 flex flex-col flex-shrink-0 h-screen overflow-y-auto no-scrollbar",
            @sidebar_lg_width_class
          ]}
        >
          <div class="flex items-center justify-between px-8 py-6 border-b border-slate-200 dark:border-slate-700 h-[88px]">
            <.link navigate={@home_path}>
              {render_slot(@logo)}
            </.link>
          </div>

          <div class="p-3 pt-6">
            <.sidebar_menu
              :if={@main_menu_items != []}
              menu_items={@main_menu_items}
              current_page={@current_page}
              title={@sidebar_title}
            />
          </div>

          <div class="flex flex-col gap-6 mt-auto p-3">
            <.usage_box
              :if={@show_usage_box}
              plan={gettext("Business")}
              limits={[
                %{
                  name: gettext("Usage"),
                  unit: gettext("credits"),
                  current: 5000,
                  max: 15000
                }
              ]}
            />
            <.wide_theme_switch />
          </div>
        </aside>
      </div>

      <div class={[
        "bg-white dark:bg-slate-900",
        "flex flex-col flex-1 overflow-y-auto no-scrollbar",
        "border-l border-slate-200 dark:border-slate-700"
      ]}>
        <header class={[
          "z-30 border-b border-slate-200 dark:border-slate-700",
          @header_bg_class,
          @header_border_class
        ]}>
          <div class="flex items-center justify-between h-[88px] -mb-px">
            <div :if={Util.present?(@dropdown)} class="px-6 xl:px-8 hidden md:flex">
              {render_slot(@dropdown)}
            </div>

            <.topbar_links
              class="items-center justify-end flex-1 gap-4 px-8 hidden xl:flex"
              links={[
                %{
                  to: ~p"/",
                  label: "Home page"
                },
                %{
                  to: ~p"/app/blog",
                  label: "Blog",
                  link_type: "live_redirect"
                },
                %{
                  to: ~p"/app/docs",
                  label: "Docs",
                  link_type: "live_redirect"
                }
              ]}
            />

            <.user_topbar_menu
              class="flex items-center gap-3 h-full ml-auto border-l border-slate-200 dark:border-slate-700"
              current_user={@current_user}
              user_menu_items={@user_menu_items}
            />
          </div>
        </header>

        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # Private

  attr :class, :string, default: "", doc: "CSS class"
  attr :version, :string, required: true, doc: "App version"

  defp version_number(assigns) do
    ~H"""
    <div class={[
      "px-2 py-1 rounded-lg border border-slate-700 justify-center items-center gap-2.5 inline-flex",
      @class
    ]}>
      <div class="text-slate-400 text-xs font-medium">
        {@version}
      </div>
    </div>
    """
  end

  # We load Alpine state dynamically in this way because we need to persist the sidebar isCollapsed state
  # across page reloads when it's togglable. This requires the Alpine Persist plugin, and throws a JS error
  # if the plugin is missing, so this reduces that impact as much as possible.

  defp x_persist_collapsed(%{collapsible: true, default_collapsed: default_collapsed}),
    do: "isCollapsed: $persist(#{default_collapsed})"

  defp x_persist_collapsed(_), do: "isCollapsed: false"
end
