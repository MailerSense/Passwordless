defmodule PasswordlessWeb.Components.SidebarLayout do
  @moduledoc """
  A responsive layout with a left sidebar (main menu), as well as a drop down menu up the top right (user menu).

  Note that in order to utilise the collapsible sidebar feature, you must install the Alpine Persist plugin. See https://alpinejs.dev/plugins/persist for more information.
  """
  use Phoenix.Component, global_prefixes: ~w(x-)
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.SidebarMenu
  import PasswordlessWeb.Components.SidebarSectionMenu
  import PasswordlessWeb.Components.ThemeSwitch
  import PasswordlessWeb.Components.UsageBox
  import PasswordlessWeb.Components.UserTopbarMenu

  attr :nonce, :string, doc: "the nonce"

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

  attr :app_menu_items, :list,
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

  slot :inner_block, required: true, doc: "The main content of the page."

  slot :logo,
    doc: "Your logo. This will automatically sit within a link to the home_path attribute."

  slot :dropdown,
    doc: "Your logo. This will automatically sit within a link to the home_path attribute."

  def sidebar_layout(assigns) do
    ~H"""
    <div class="flex h-screen bg-white dark:bg-slate-900" x-data="sidebar">
      <div class="pc-sidebar__container">
        <.sidebar_section_menu menu_items={@section_menu_items} current_section={@current_section} />

        <div class="flex flex-col gap-2 items-center justify-center">
          <span
            id="collapse-icon"
            class="group transition duration-200 cursor-pointer"
            phx-hook="TippyHook"
            data-tippy-content={gettext("Toggle Sidebar")}
            data-tippy-placement="right"
            x-on:click.stop="closeSidebar"
            aria-controls="sidebar"
          >
            <.icon
              name="custom-board-document"
              class="w-10 h-10 text-white/60 group-hover:bg-primary-500 transition duration-200"
              x-bind:class="sidebarOpenClass"
            />
          </span>
        </div>
      </div>

      <aside id="sidebar" role="navigation" class="pc-sidebar__aside" x-show="sidebarOpen">
        <div class="flex items-center justify-between px-8 py-6 border-b border-slate-700 h-[88px]">
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
          <.usage_box plan={gettext("Essential")} usage={1240} usage_max={2000} />
          <.wide_theme_switch />
        </div>
      </aside>

      <div class="pc-sidebar__header-container">
        <header class="pc-sidebar__header">
          <div :if={Util.present?(@dropdown)} class="px-6 hidden md:flex">
            {render_slot(@dropdown)}
          </div>

          <.topbar_links links={[
            %{
              to: ~p"/home",
              label: "Home Page",
              link_type: "live_redirect"
            },
            %{
              to: ~p"/support",
              label: "Support",
              link_type: "live_redirect"
            },
            %{
              to: ~p"/embed/install",
              label: "Docs",
              link_type: "live_redirect"
            }
          ]} />

          <.user_topbar_menu
            class="flex items-center gap-3 h-full ml-auto border-l border-slate-200 dark:border-slate-700"
            current_user={@current_user}
            user_menu_items={@user_menu_items}
          />
        </header>

        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
