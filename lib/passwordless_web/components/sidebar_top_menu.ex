defmodule PasswordlessWeb.Components.UserTopbarMenu do
  @moduledoc false

  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Avatar
  import PasswordlessWeb.Components.Dropdown
  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Input
  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Components.ThemeSwitch
  import PasswordlessWeb.Helpers

  attr :class, :any, default: "", doc: "CSS class"
  attr :rest, :global

  attr :current_user, :map, default: nil

  attr :user_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the user menu."

  attr :project_menu_items, :list,
    default: [],
    doc: "The items that will be displayed in the user menu."

  def user_topbar_menu(assigns) do
    ~H"""
    <div {@rest} class={["flex items-center gap-3", @class]}>
      <.theme_switch />

      <.dropdown
        label={PasswordlessWeb.Helpers.user_project_name(@current_user)}
        variant="outline"
        placement="right"
      >
        <.dropdown_menu_item link_type="live_redirect" to={~p"/app/project/new"}>
          <.icon name="remix-add-line" class="w-5 h-5" />
          {gettext("New Project")}
        </.dropdown_menu_item>
        <.form
          :for={project <- @project_menu_items}
          for={nil}
          action={~p"/app/project/switch"}
          method="post"
        >
          <.input type="hidden" name="project_id" value={project.id} />
          <button class="pc-dropdown__menu-item">
            <.icon name="remix-instance-line" class="w-5 h-5" />
            <span class="line-clamp-1">{project.name}</span>
          </button>
        </.form>
      </.dropdown>

      <.dropdown placement="left">
        <:trigger_element>
          <%= if user_impersonated?(@current_user) do %>
            <.avatar icon="remix-alert-fill" color="danger" />
          <% else %>
            <.avatar />
          <% end %>
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
                  class={[
                    "w-5 h-5",
                    if(child_item[:color] == :red, do: "text-danger-700 dark:text-danger-400")
                  ]}
                />
                <span class={[
                  if(child_item[:color] == :red, do: "text-danger-700 dark:text-danger-400")
                ]}>
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
