defmodule PasswordlessWeb.Components.Card do
  @moduledoc false
  use Phoenix.Component

  import PasswordlessWeb.Components.Icon

  attr :to, :string, default: nil, doc: "link path"
  attr :class, :string, default: "", doc: "CSS class"
  attr :variant, :string, default: "card", values: ["card", "link"]

  attr :rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type title)

  slot :inner_block, required: false

  def card(assigns) do
    ~H"""
    <%= if @variant == "link" do %>
      <.link {@rest} class={["pc-card", "pc-card--#{@variant}", @class]} navigate={@to}>
        <article class="pc-card__inner">
          {render_slot(@inner_block)}
        </article>
      </.link>
    <% else %>
      <div {@rest} class={["pc-card", "pc-card--#{@variant}", @class]}>
        <article class="pc-card__inner">
          {render_slot(@inner_block)}
        </article>
      </div>
    <% end %>
    """
  end

  attr(:aspect_ratio_class, :string, default: "aspect-video", doc: "aspect ratio class")
  attr(:src, :string, default: nil, doc: "hosted image URL")
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global, include: ~w(loading alt title))
  slot(:inner_block, required: false)

  def card_media(assigns) do
    ~H"""
    <%= if @src do %>
      <img {@rest} src={@src} class={["pc-card__image", @aspect_ratio_class, @class]} />
    <% else %>
      <div {@rest} class={["pc-card__image-placeholder", @aspect_ratio_class, @class]}></div>
    <% end %>
    """
  end

  attr(:src, :string, default: nil, doc: "creates an icon")
  attr(:class, :any, default: nil, doc: "CSS class")

  def card_icon(assigns) do
    ~H"""
    <span class={["pc-card__icon", @class]}>
      <img src={@src} class="pc-card__icon-image" />
    </span>
    """
  end

  attr(:src, :string, default: nil, doc: "creates an icon")
  attr(:class, :any, default: nil, doc: "CSS class")
  slot(:badge)

  def card_image(assigns) do
    ~H"""
    <div class={["pc-card__image", @class]}>
      <img src={@src} class="pc-card__image-image" loading="lazy" />
      <div :if={Util.present?(@badge)} class="pc-card__badge">
        {render_slot(@badge)}
      </div>
    </div>
    """
  end

  attr(:heading, :string, default: nil, doc: "creates a heading")
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:icon, :string, default: nil, doc: "creates a heading")
  attr(:icon_class, :string, default: nil, doc: "creates a heading")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card_content(assigns) do
    ~H"""
    <div {@rest} class={["pc-card__content", @class]}>
      <%= if @icon do %>
        <div class="pc-card__heading-wrapper">
          <.icon name={@icon} class={["pc-card__heading-icon", @icon_class]} />
          <h2 :if={@heading} class="pc-card__heading">
            {@heading}
          </h2>
        </div>
      <% else %>
        <h2 :if={@heading} class="pc-card__heading">
          {@heading}
        </h2>
      <% end %>

      {render_slot(@inner_block) || @label}
    </div>
    """
  end

  attr(:icon, :string, default: nil, doc: "sets an icon for the card")
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def card_footer(assigns) do
    ~H"""
    <div {@rest} class={["pc-card__footer", @class]}>
      {render_slot(@inner_block)}
      <.icon :if={@icon} name={@icon} />
    </div>
    """
  end
end
