defmodule PasswordlessWeb.Components.Button do
  @moduledoc false
  use Phoenix.Component

  alias PasswordlessWeb.Components.Icon
  alias PasswordlessWeb.Components.Link
  alias PasswordlessWeb.Components.Loading

  require Logger

  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl", "wide"], doc: "button sizes"

  attr :variant, :string,
    default: "solid",
    values: ["solid", "outline"],
    doc: "button variant"

  attr :color, :string,
    default: "primary",
    values: [
      "primary",
      "secondary",
      "danger",
      "gray",
      "light",
      "light-flat",
      "wireframe"
    ],
    doc: "button color"

  attr :to, :string, default: nil, doc: "link path"
  attr :loading, :boolean, default: false, doc: "indicates a loading state"
  attr :disabled, :boolean, default: false, doc: "indicates a disabled state"
  attr :icon, :string, default: nil, doc: "name of a Heroicon at the front of the button"
  attr :with_icon, :boolean, default: false, doc: "adds some icon base classes"

  attr :link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :class, :string, default: "", doc: "CSS class"
  attr :label, :string, default: nil, doc: "labels your button"
  attr :title, :string, default: nil, doc: "labels your button"

  attr :rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type value name form title)

  slot :inner_block, required: false

  def button(assigns) do
    assigns =
      assign(assigns, :classes, button_classes(assigns))

    ~H"""
    <Link.a
      to={@to}
      link_type={@link_type}
      class={@classes}
      disabled={@disabled}
      title={@label || @title}
      {@rest}
    >
      <%= if @loading do %>
        <Loading.spinner show={true} size_class={"pc-button__spinner-icon--#{@size}"} />
      <% else %>
        <%= if @icon do %>
          <Icon.icon name={@icon} class={"pc-button__spinner-icon--#{@size}"} />
        <% end %>
      <% end %>

      {render_slot(@inner_block) || @label || @title}
    </Link.a>
    """
  end

  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"]

  attr :color, :string,
    default: "primary",
    values: [
      "primary",
      "danger",
      "light",
      "wireframe"
    ]

  attr :variant, :string,
    default: "solid",
    values: ["solid", "outline"],
    doc: "button variant"

  attr :to, :string, default: nil, doc: "link path"
  attr :icon, :string, default: nil, doc: "name of a Heroicon at the front of the button"
  attr :loading, :boolean, default: false, doc: "indicates a loading state"
  attr :disabled, :boolean, default: false, doc: "indicates a disabled state"

  attr :link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :class, :string, default: "", doc: "CSS class"
  attr :tooltip, :string, default: nil, doc: "tooltip text"

  attr :rest, :global,
    include:
      ~w(id method download hreflang ping referrerpolicy rel target type value name form title phx-hook data-tippy-content)

  slot :inner_block, required: false

  def icon_button(%{disabled: true, rest: %{"phx-hook": "TippyHook"}} = assigns) do
    assigns =
      assign(
        assigns,
        :variant_suffix,
        if(assigns[:variant] == "solid", do: "", else: "--#{assigns[:variant]}")
      )

    ~H"""
    <span
      class={[
        "pc-icon-button" <> @variant_suffix,
        @disabled && "pc-button--disabled",
        "pc-icon-button--#{@color}#{@variant_suffix}",
        "pc-icon-button--#{@size}",
        @class
      ]}
      {@rest}
    >
      <Icon.icon name={@icon} class={"pc-button__spinner-icon--#{@size}"} />
    </span>
    """
  end

  def icon_button(assigns) do
    assigns =
      assign(
        assigns,
        :variant_suffix,
        if(assigns[:variant] == "solid", do: "", else: "--#{assigns[:variant]}")
      )

    ~H"""
    <Link.a
      to={@to}
      link_type={@link_type}
      class={[
        "pc-icon-button" <> @variant_suffix,
        @disabled && "pc-button--disabled",
        "pc-icon-button--#{@color}#{@variant_suffix}",
        "pc-icon-button--#{@size}",
        @class
      ]}
      disabled={@disabled}
      {@rest}
    >
      <Icon.icon name={@icon} class={"pc-button__spinner-icon--#{@size}"} />
    </Link.a>
    """
  end

  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"]

  attr :color, :string,
    default: "primary",
    values: [
      "primary",
      "success",
      "danger",
      "light",
      "wireframe"
    ]

  attr :variant, :string,
    default: "solid",
    values: ["solid", "outline"],
    doc: "button variant"

  attr :icon, :string, default: nil, doc: "name of a Heroicon at the front of the button"
  attr :disabled, :boolean, default: false, doc: "indicates a disabled state"

  attr :class, :string, default: "", doc: "CSS class"
  attr :tooltip, :string, default: nil, doc: "tooltip text"

  attr :event, :any,
    default: nil,
    doc: "the event to trigger on click."

  attr :rest, :global,
    include: ~w(method download hreflang ping referrerpolicy rel target type value name form title phx-value-id)

  slot :inner_block, required: false

  def icon_form_button(assigns) do
    assigns =
      assign(
        assigns,
        :variant_suffix,
        if(assigns[:variant] == "solid", do: "", else: "--#{assigns[:variant]}")
      )

    ~H"""
    <button
      type="button"
      class={[
        "pc-icon-button" <> @variant_suffix,
        @disabled && "pc-button--disabled",
        "pc-icon-button--#{@color}#{@variant_suffix}",
        "pc-icon-button--#{@size}",
        @class
      ]}
      disabled={@disabled}
      phx-click={@event}
      {@rest}
    >
      <Icon.icon name={@icon} class={"pc-button__spinner-icon--#{@size}"} />
    </button>
    """
  end

  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"], doc: "button sizes"

  attr :variant, :string,
    default: "solid",
    values: ["solid", "outline"],
    doc: "button variant"

  attr :color, :string,
    default: "primary",
    values: [
      "action",
      "primary",
      "danger",
      "light",
      "wireframe"
    ],
    doc: "button color"

  attr :class, :string, default: nil, doc: "the class to add to this element"
  attr :icon, :string, default: nil, doc: "name of a Heroicon at the front of the button"
  attr :rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type value name form title)
  attr :disabled, :boolean, default: false, doc: "indicates a disabled state"

  def trigger_icon(assigns) do
    assigns =
      assign(
        assigns,
        :variant_suffix,
        if(assigns[:variant] == "solid", do: "", else: "--#{assigns[:variant]}")
      )

    ~H"""
    <span
      class={[
        "pc-icon-button" <> @variant_suffix,
        @disabled && "pc-button--disabled",
        "pc-icon-button--#{@color}#{@variant_suffix}",
        "pc-icon-button--#{@size}",
        @class
      ]}
      disabled={@disabled}
      {@rest}
    >
      <Icon.icon name={@icon} class={["pc-button__spinner-icon--#{@size}", @class]} />
    </span>
    """
  end

  attr :to, :string, default: nil, doc: "link path"
  attr :class, :string, default: nil, doc: "the class to add to this element"
  attr :label, :string, default: nil, doc: "name of a Heroicon at the front of the button"

  def start_for_free_button(assigns) do
    ~H"""
    <.button to={@to} label={@label} link_type="a" />
    """
  end

  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"], doc: "button sizes"

  attr :variant, :string,
    default: "solid",
    values: ["solid", "outline"],
    doc: "button variant"

  attr :color, :string,
    default: "primary",
    values: [
      "action",
      "primary",
      "danger",
      "light",
      "wireframe"
    ],
    doc: "button color"

  attr :class, :string, default: "", doc: "CSS class"
  attr :label, :string, default: nil, doc: "labels your button"
  attr :after_copy_label, :string, default: "Copied!", doc: "labels your button"
  attr :value, :string, default: "", doc: "Value"
  attr :rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type value name form title)
  slot :inner_block, required: false

  def copy_button(assigns) do
    assigns =
      assign(assigns, :classes, button_classes(assigns))

    ~H"""
    <span
      id={@value <> "-copy-button"}
      class={@classes}
      phx-hook="ClipboardHook"
      data-content={@value}
      {@rest}
    >
      <div class="before-copied flex items-center gap-3 whitespace-nowrap">
        <Icon.icon name="remix-clipboard-line" class={"pc-button__spinner-icon--#{@size}"} />
        {render_slot(@inner_block) || @label}
      </div>
      <div class="hidden after-copied items-center gap-3 whitespace-nowrap">
        {@after_copy_label}
      </div>
    </span>
    """
  end

  # Private

  defp button_classes(opts) do
    opts = %{
      size: opts[:size] || "md",
      variant: opts[:variant] || "solid",
      color: opts[:color] || "primary",
      loading: opts[:loading] || false,
      disabled: opts[:disabled] || false,
      with_icon: opts[:with_icon] || opts[:icon] || false,
      user_added_classes: opts[:class] || ""
    }

    [
      "pc-button",
      "pc-button--#{String.replace(opts.color, "_", "-")}#{if opts.variant == "solid", do: "", else: "-#{opts.variant}"}",
      "pc-button--#{opts.size}",
      opts.user_added_classes,
      opts.loading && "pc-button--loading",
      opts.disabled && "pc-button--disabled",
      opts.with_icon && "pc-button--with-icon#{if opts.size == "xs", do: "--xs", else: ""}"
    ]
  end
end
