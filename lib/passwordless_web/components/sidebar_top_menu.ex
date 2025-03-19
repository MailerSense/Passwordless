defmodule PasswordlessWeb.Components.UserTopbarMenu do
  @moduledoc false

  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Avatar
  import PasswordlessWeb.Components.Dropdown
  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Helpers

  attr :class, :any, default: "", doc: "CSS class"
  attr :rest, :global

  attr :current_user, :map, default: nil

  attr :user_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the user menu."

  attr :app_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the user menu."

  def user_topbar_menu(assigns) do
    ~H"""
    <div
      {@rest}
      class={[
        "flex items-center gap-3 h-full ml-auto border-l border-gray-200 dark:border-gray-700",
        @class
      ]}
    >
      <.dropdown placement="center">
        <:trigger_element>
          <div class="p-6 items-center gap-6 2xl:gap-16 inline-flex h-full">
            <div class="rounded-lg items-center gap-3 flex">
              <%= if user_impersonated?(@current_user) do %>
                <.avatar icon="remix-alert-fill" size="lg" color="danger" />
              <% else %>
                <.avatar name={user_name(@current_user)} size="lg" color="black" />
              <% end %>

              <div class="flex-col justify-start items-start inline-flex gap-1">
                <div class="text-gray-900 dark:text-white text-base font-semibold leading-normal">
                  {user_name(@current_user)}
                </div>
                <div class="text-gray-500 dark:text-gray-400 text-xs font-normal">
                  {user_email(@current_user)}
                </div>
                <%= if user_impersonated?(@current_user) do %>
                  <span class="text-danger-500 dark:text-danger-400 text-xs font-bold">
                    {gettext("Impersonated by %{name}",
                      name: user_impersonator_name(@current_user)
                    )}
                  </span>
                <% end %>
              </div>
            </div>
            <.icon name="remix-arrow-down-s-line" class="w-6 h-6" />
          </div>
        </:trigger_element>
        <%= for child_item <- @user_menu_items do %>
          <%= case child_item do %>
            <% %{separator: true} -> %>
              <.dropdown_separator />
            <% _ -> %>
              <.dropdown_menu_item
                to={child_item.path}
                label={child_item.label}
                method={if child_item[:method], do: child_item[:method], else: nil}
                link_type={child_item[:link_type] || "a"}
              >
                <.icon
                  :if={child_item[:icon]}
                  name={child_item[:icon]}
                  class={["w-5 h-5", if(child_item[:color] == :red, do: "text-red-500")]}
                />
                <span class={[if(child_item[:color] == :red, do: "text-red-500")]}>
                  {child_item.label}
                </span>
              </.dropdown_menu_item>
          <% end %>
        <% end %>
      </.dropdown>
    </div>
    """
  end

  attr :class, :any, default: "", doc: "CSS class"
  attr :rest, :global
  attr :links, :list, default: []

  def topbar_links(assigns) do
    ~H"""
    <div {@rest} class={["h-[18px] justify-start items-center inline-flex", @class]}>
      <.a
        :for={l <- @links}
        to={l.to}
        label={l.label}
        link_type={l[:link_type] || "a"}
        class={[
          case l[:kind] do
            :admin -> "text-danger-700 dark:text-danger-400"
            :oban -> "text-yellow-500 dark:text-yellow-400"
            _ -> "text-slate-500 dark:text-slate-400"
          end,
          "text-xs font-medium"
        ]}
      />
    </div>
    """
  end
end
