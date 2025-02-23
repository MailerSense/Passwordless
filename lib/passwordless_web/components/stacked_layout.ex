defmodule PasswordlessWeb.Components.StackedLayout do
  @moduledoc """
  A responsive layout with a left sidebar (main menu), as well as a drop down menu up the top right (user menu).

  Note that in order to utilise the collapsible sidebar feature, you must install the Alpine Persist plugin. See https://alpinejs.dev/plugins/persist for more information.
  """
  use Phoenix.Component, global_prefixes: ~w(x-)
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Avatar
  import PasswordlessWeb.Components.Container
  import PasswordlessWeb.Components.Dropdown
  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Components.UserTopbarMenu
  import PasswordlessWeb.Helpers

  attr :max_width, :string,
    default: "lg",
    values: ["sm", "md", "lg", "xl", "full"],
    doc: "sets container max-width"

  attr :current_user, :map, default: nil

  attr :current_page, :atom,
    required: true,
    doc: "The current page. This will be used to highlight the current page in the menu."

  attr :project_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the main menu in the sidebar."

  attr :main_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the main menu in the sidebar."

  attr :user_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the user menu."

  attr :home_path, :string,
    default: "/",
    doc: "The path to the home page. When a user clicks the logo, they will be taken to this path."

  attr :header_bg_class, :string, default: "bg-white/50 dark:bg-slate-900/50 backdrop-blur-md shadow-m2"
  attr :header_border_class, :string, default: "border-b border-slate-200 dark:border-slate-700"

  slot :inner_block, required: true, doc: "The main content of the page."

  slot :logo,
    doc: "Your logo. This will automatically sit within a link to the home_path attribute."

  def stacked_layout(assigns) do
    ~H"""
    <div class="h-screen overflow-y-auto bg-slate-100 dark:bg-slate-900">
      <header
        class={[
          @header_bg_class,
          @header_border_class,
          "sticky top-0 z-30"
        ]}
        x-data="{mobileMenuOpen: false}"
      >
        <.container max_width={@max_width} class="relative flex h-16 w-full">
          <%!-- mobile menu --%>
          <div
            class={[
              "lg:hidden absolute w-screen top-[65px] left-0",
              "bg-white dark:bg-slate-800 shadow-lg z-10"
            ]}
            @click.away="mobileMenuOpen = false"
            x-cloak
            x-show="mobileMenuOpen"
            x-transition:enter="transition transform ease-out duration-100"
            x-transition:enter-start="transform opacity-0 scale-95"
            x-transition:enter-end="transform opacity-100 scale-100"
            x-transition:leave="transition ease-in duration-75"
            x-transition:leave-start="transform opacity-100 scale-100"
            x-transition:leave-end="transform opacity-0 scale-95"
          >
            <div class="pt-2 pb-3 space-y-1">
              <%= for menu_item <- @main_menu_items do %>
                <.link
                  :if={menu_item[:path]}
                  patch={menu_item.path}
                  class={mobile_menu_item_class(@current_page, menu_item[:name])}
                >
                  {menu_item.label}
                </.link>
                <div :if={menu_item[:menu_items]}>
                  <.link
                    :for={sub_menu_item <- menu_item[:menu_items]}
                    patch={sub_menu_item.path}
                    class={mobile_menu_item_class(@current_page, sub_menu_item[:name])}
                  >
                    {sub_menu_item.label}
                  </.link>
                </div>
              <% end %>
            </div>

            <div class="pt-4 pb-3 border-t border-slate-200 dark:border-slate-700">
              <div class="flex items-center justify-between px-4">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <.avatar name={user_name(@current_user)} color="primary" />
                  </div>
                  <div class="ml-3">
                    <div class="text-base font-medium text-slate-800 dark:text-slate-200">
                      {user_name(@current_user)}
                    </div>
                  </div>
                </div>
              </div>

              <div class="mt-3 space-y-1">
                <.a
                  :for={menu_item <- @user_menu_items}
                  link_type="live_patch"
                  to={menu_item.path}
                  label={menu_item.label}
                  class={mobile_menu_item_class(@current_page, menu_item[:name])}
                />
              </div>
            </div>
          </div>

          <%!-- standard menu --%>
          <div class="flex w-full justify-between relative">
            <.link navigate={@home_path} class="flex items-center justify-center">
              {render_slot(@logo)}
            </.link>
            <!-- For grouped menu items -->
            <nav class={[
              "hidden h-full absolute left-1/2 transform -translate-x-1/2 lg:flex lg:gap-x-6"
            ]}>
              <.main_menu_item
                :for={menu_item <- @main_menu_items}
                menu_item={menu_item}
                current_page={@current_page}
              />
            </nav>
            <!-- Topbar menu -->
            <.user_topbar_menu
              current_user={@current_user}
              user_menu_items={@user_menu_items}
              project_menu_items={@project_menu_items}
              class="hidden lg:flex"
            />
          </div>

          <div class="flex items-center -mr-2 lg:hidden">
            <button
              type="button"
              class="inline-flex items-center justify-center p-2 text-slate-400 rounded-md dark:text-slate-600 hover:text-slate-500 hover:bg-slate-100 dark:hover:text-slate-400 dark:hover:bg-slate-900 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-primary-500"
              aria-controls="mobile-menu"
              @click="mobileMenuOpen = !mobileMenuOpen"
              x-bind:aria-expanded="mobileMenuOpen.toString()"
            >
              <span class="sr-only">
                Open main menu
              </span>

              <div
                class="w-6 h-6"
                x-bind:class="{ 'hidden': mobileMenuOpen, 'block': !(mobileMenuOpen) }"
                x-cloak
              >
                <.icon name="remix-arrow-down-s-line" class="w-6 h-6" />
              </div>

              <div
                class="w-6 h-6"
                x-bind:class="{ 'block': mobileMenuOpen, 'hidden': !(mobileMenuOpen) }"
                x-cloak
              >
                <.icon name="remix-arrow-down-s-line" class="w-6 h-6" />
              </div>
            </button>
          </div>
        </.container>
      </header>

      <.container max_width={@max_width} class="pb-12">
        {render_slot(@inner_block)}
      </.container>
    </div>
    """
  end

  # Private

  attr :current_page, :string, required: true
  attr :menu_item, :map, required: true

  def main_menu_item(assigns) do
    assigns =
      assign(assigns, :active?, nav_menu_item_active?(assigns.menu_item, assigns.current_page))

    ~H"""
    <.a
      :if={!@menu_item[:menu_items]}
      to={@menu_item[:path]}
      label={@menu_item.label}
      class={main_menu_item_class(@active?)}
      link_type="live_redirect"
    />

    <div :if={@menu_item[:menu_items]} class={["relative", main_menu_item_class(@active?)]}>
      <.dropdown placement="right">
        <:trigger_element>
          <div class="inline-flex items-center justify-center w-full focus:outline-none">
            {@menu_item.label}
            <.icon
              name="remix-arrow-down-s-line"
              class="w-4 h-4 ml-1 -mr-1 text-slate-400 dark:text-slate-100"
            />
          </div>
        </:trigger_element>

        <.dropdown_menu_item
          :for={submenu_item <- @menu_item.menu_items}
          :if={submenu_item[:path]}
          label={submenu_item.label}
          to={submenu_item.path}
          link_type="live_redirect"
          class={dropdown_item_class(nav_menu_item_active?(submenu_item, @current_page))}
        />
      </.dropdown>
    </div>
    """
  end

  defp nav_menu_item_active?(menu_item, current_page) do
    menu_item[:name] == current_page ||
      Enum.any?(menu_item[:menu_items] || [], fn menu_item ->
        nav_menu_item_active?(menu_item, current_page)
      end)
  end

  defp dropdown_item_class(true), do: "bg-slate-100 dark:bg-slate-700"
  defp dropdown_item_class(false), do: ""

  defp main_menu_item_base_class,
    do: "inline-flex items-center px-1 text-sm font-medium leading-5 transition duration-150 ease-in-out top-menu-item"

  defp main_menu_item_class(true), do: ["active text-slate-900 dark:text-slate-100", main_menu_item_base_class()]

  defp main_menu_item_class(false),
    do: [
      "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 dark:focus:text-slate-300 dark:text-slate-400",
      main_menu_item_base_class()
    ]

  defp mobile_menu_item_class(page, page),
    do:
      "block py-2 pl-3 pr-4 text-base font-medium text-primary-700 border-l-4 border-primary-500 bg-primary-50 dark:text-primary-300 dark:bg-primary-700"

  defp mobile_menu_item_class(_, _),
    do:
      "block py-2 pl-3 pr-4 text-base font-medium text-slate-500 border-l-4 border-transparent hover:bg-slate-50 hover:border-slate-300 hover:text-slate-700 dark:text-slate-400 dark:bg-slate-800 dark:hover:bg-slate-700 dark:hover:border-slate-700 dark:hover:text-slate-300"
end
