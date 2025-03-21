defmodule PasswordlessWeb.Components.Tabs do
  @moduledoc false
  use Phoenix.Component

  alias PasswordlessWeb.Components.Icon
  alias PasswordlessWeb.Components.Link

  attr :variant, :string, default: "basic", values: ["basic", "native", "contrast", "buttons"]
  attr :class, :any, default: "", doc: "CSS class"
  attr :rest, :global
  slot :inner_block, required: false

  def tabs(assigns) do
    ~H"""
    <nav {@rest} class={["pc-tabs--#{@variant}", @class]} role="tablist">
      {render_slot(@inner_block)}
    </nav>
    """
  end

  attr(:class, :string, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "labels your tab")
  attr(:icon, :string, default: nil, doc: "icons your tab")
  attr(:count, :integer, default: nil, doc: "icons your tab")
  attr(:path, :string, default: nil, doc: "link path")
  attr(:is_active, :boolean, default: false, doc: "indicates the current tab")
  attr(:variant, :string, default: "basic", values: ["basic", "native", "contrast", "buttons"])
  attr(:rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type))

  attr(:link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect"]
  )

  def tab(assigns) do
    ~H"""
    <Link.a
      to={@path}
      class={get_tab_class(@is_active, @variant) ++ [@class]}
      link_type={@link_type}
      title={@label}
      role="tab"
      {@rest}
    >
      <%= if @icon do %>
        <Icon.icon name={@icon} />
      <% end %>
      {@label}
      <%= if @count do %>
        <span class="pc-badge pc-badge--contrast pc-badge--sm">
          {@count}
        </span>
      <% end %>
    </Link.a>
    """
  end

  attr :id, :string, default: nil
  attr :rest, :global, include: ~w(class)
  attr :mode, :string, default: "link", values: ["link", "form", "live"]
  attr :field, :any, default: nil
  attr :name_field, :any, default: nil
  attr :variant, :string, default: "basic", values: ["basic", "native", "contrast", "buttons"]

  attr :menu_items, :list,
    required: true,
    doc: "list of maps with keys :name, :path, :label, :icon (atom)"

  attr :current_tab, :atom, default: nil
  attr :name, :any, doc: "the name of the input. If not passed, it will be generated automatically from the field"
  attr :value, :any, doc: "the value of the input. If not passed, it will be generated automatically from the field"
  attr :name_name, :any, doc: "the name of the input. If not passed, it will be generated automatically from the field"
  attr :name_value, :any, doc: "the value of the input. If not passed, it will be generated automatically from the field"

  def tab_menu(
        %{mode: "form", field: %Phoenix.HTML.FormField{} = field, name_field: %Phoenix.HTML.FormField{} = name_field} =
          assigns
      ) do
    assigns
    |> assign(field: nil, name_field: nil, id: assigns.id || field.id)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> assign_new(:name_name, fn -> name_field.name end)
    |> assign_new(:name_value, fn -> name_field.value end)
    |> tab_menu()
  end

  def tab_menu(assigns) do
    assigns = assign_new(assigns, :id, fn -> Util.id("tab-menu") end)

    ~H"""
    <%= case @mode do %>
      <% "live" -> %>
        <.tabs variant={@variant} {@rest}>
          <.tab
            :for={item <- @menu_items}
            {item}
            is_active={item.name == @current_tab}
            variant={@variant}
            phx-click="switch_tab"
            phx-value-tab={item.name}
            phx-value-source={@id}
          />
        </.tabs>
      <% "link" -> %>
        <.tabs variant={@variant} {@rest}>
          <.tab
            :for={item <- @menu_items}
            {item}
            is_active={item.name == @current_tab}
            variant={@variant}
          />
        </.tabs>
      <% "form" -> %>
        <input type="hidden" name={@name_name} value={@name_value} />

        <div id={@id} phx-hook="BadgeSelectHook" {js_attributes("container", @current_tab)}>
          <input type="hidden" name={@name} value={@value} />
          <.tabs variant={@variant} {@rest}>
            <span
              :for={item <- @menu_items}
              role="tab"
              class={["pc-tab__pill--#{@variant}", "cursor-pointer"]}
              {js_attributes("tab", item, @variant)}
            >
              <%= if item[:icon] do %>
                <Icon.icon name={item[:icon]} />
              <% end %>
              {item.label}
            </span>
          </.tabs>
        </div>
    <% end %>
    """
  end

  # Private

  defp get_tab_class(is_active, variant) do
    base_classes = "pc-tab__pill"

    active_classes =
      if is_active,
        do: "pc-tab__pill--is-active",
        else: "pc-tab__pill--is-not-active"

    Enum.map([base_classes, active_classes], fn class -> "#{class}--#{variant}" end)
  end

  defp js_attributes("container", current_tab) do
    %{
      "x-on:reset": "tab = '#{current_tab}'",
      "x-data": "{
        tab: '#{current_tab}',
        input: '#{current_tab}',
        init() {
          this.$watch('input', (value) => {
            $dispatch('selected-change', {value: value});
          });
        }
      }"
    }
  end

  defp js_attributes("tab", %{name: name, clear: true}, variant) do
    %{
      "x-on:click": "tab = '#{name}'; input = null",
      "x-bind:class": "{
        'pc-tab__pill--is-active--#{variant}': tab === '#{name}',
        'pc-tab__pill--is-not-active--#{variant}': tab !== '#{name}'
      }"
    }
  end

  defp js_attributes("tab", %{name: name}, variant) do
    %{
      "x-on:click": "tab = '#{name}'; input = '#{name}'",
      "x-bind:class": "{
        'pc-tab__pill--is-active--#{variant}': tab === '#{name}',
        'pc-tab__pill--is-not-active--#{variant}': tab !== '#{name}'
      }"
    }
  end
end
