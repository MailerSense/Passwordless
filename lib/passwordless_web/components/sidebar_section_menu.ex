defmodule PasswordlessWeb.Components.SidebarSectionMenu do
  @moduledoc """
  Functions concerned with rendering aspects of the sidebar section layout.
  """

  use Phoenix.Component, global_prefixes: ~w(x-)
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link

  attr :menu_items, :list, required: true
  attr :current_section, :atom, required: true

  def sidebar_section_menu(assigns) do
    ~H"""
    <nav class="flex flex-col gap-2">
      <.sidebar_section_menu_item
        :for={item <- @menu_items}
        {item}
        current_section={@current_section}
      />
    </nav>
    """
  end

  attr :name, :atom, default: nil
  attr :path, :string, default: nil
  attr :label, :string
  attr :icon, :string, default: nil
  attr :link_type, :string, default: "live_redirect"
  attr :current_section, :atom

  def sidebar_section_menu_item(assigns) do
    ~H"""
    <.a
      id={"section_menu_item_#{@label |> String.downcase() |> String.replace(" ", "_")}_anchor"}
      to={@path}
      link_type={@link_type}
      class={menu_item_classes(@current_section, @name)}
      title={@label}
      phx-hook="TippyHook"
      data-tippy-content={@label}
      data-tippy-placement="right"
    >
      <.icon name={@icon} class={menu_icon_classes(@current_section, @name)} />
    </.a>
    """
  end

  # Private

  defp menu_item_base, do: "p-2 transition duration-200 rounded-xl"

  # Active state
  defp menu_item_classes(page, page), do: "#{menu_item_base()} text-primary-500 bg-primary-500/20"

  # Inactive state
  defp menu_item_classes(_current_page, _link_page),
    do: "#{menu_item_base()} text-gray-400 hover:bg-gray-800 hover:text-primary-500"

  defp menu_icon_base, do: "w-8 h-8"

  # Active state
  defp menu_icon_classes(page, page), do: "#{menu_icon_base()} text-primary-500"

  # Inactive state
  defp menu_icon_classes(_current_page, _link_page), do: "#{menu_icon_base()} text-gray-400 "
end
