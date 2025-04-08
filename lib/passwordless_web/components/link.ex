defmodule PasswordlessWeb.Components.Link do
  @moduledoc false
  use Phoenix.Component

  import PasswordlessWeb.Components.Icon

  attr :class, :any, default: "", doc: "CSS class for link (either a string or list)"
  attr :link_type, :string, default: "a", values: ["a", "live_patch", "live_redirect", "button"]
  attr :label, :string, default: nil, doc: "label your link"
  attr :title, :string, default: nil, doc: "title your link"
  attr :to, :string, default: nil, doc: "link path"

  attr :styled, :boolean, default: false, doc: "title your link"

  attr :style, :string, default: "none", values: ["link", "sensitive", "delete", "none"]

  attr :disabled, :boolean,
    default: false,
    doc: "disables the link. This will turn an <a> into a <button> (<a> tags can't be disabled)"

  attr :rest, :global, include: ~w(method download)
  slot :inner_block, required: false

  def a(%{link_type: "button", disabled: true} = assigns) do
    assigns = update_in(assigns.rest, &Map.drop(&1, [:"phx-click"]))

    ~H"""
    <button
      class={[link_class(@style, @disabled), @class]}
      disabled={@disabled}
      title={@label || @title}
      aria-label={@label || @title}
      aria-disabled={@disabled}
      {@rest}
    >
      {if @label, do: @label, else: render_slot(@inner_block)}
      <.icon :if={styled?(@style)} name="remix-external-link-line" class="w-4 h-4" />
    </button>
    """
  end

  # Since the <a> tag can't be disabled, we turn it into a disabled button (looks exactly the same and does nothing when clicked)
  def a(%{disabled: true, link_type: type} = assigns) when type != "button" do
    a(Map.put(assigns, :link_type, "button"))
  end

  def a(%{link_type: "a"} = assigns) do
    ~H"""
    <.link
      href={@to}
      class={[link_class(@style, @disabled), @class]}
      title={@label || @title}
      aria-label={@label || @title}
      aria-disabled={@disabled}
      {@rest}
    >
      {if(@label, do: @label, else: render_slot(@inner_block))}
      <.icon :if={styled?(@style)} name="remix-external-link-line" class="w-4 h-4" />
    </.link>
    """
  end

  def a(%{link_type: "live_patch"} = assigns) do
    ~H"""
    <.link
      patch={@to}
      class={[link_class(@style, @disabled), @class]}
      title={@label || @title}
      aria-label={@label || @title}
      aria-disabled={@disabled}
      {@rest}
    >
      {if(@label, do: @label, else: render_slot(@inner_block))}
      <.icon :if={styled?(@style)} name="remix-external-link-line" class="w-4 h-4" />
    </.link>
    """
  end

  def a(%{link_type: "live_redirect"} = assigns) do
    ~H"""
    <.link
      navigate={@to}
      class={[link_class(@style, @disabled), @class]}
      title={@label || @title}
      aria-label={@label || @title}
      aria-disabled={@disabled}
      {@rest}
    >
      {if(@label, do: @label, else: render_slot(@inner_block))}
      <.icon :if={styled?(@style)} name="remix-external-link-line" class="w-4 h-4" />
    </.link>
    """
  end

  def a(%{link_type: "button"} = assigns) do
    ~H"""
    <button
      class={[link_class(@style, @disabled), @class]}
      disabled={@disabled}
      title={@label || @title}
      aria-label={@label || @title}
      aria-disabled={@disabled}
      {@rest}
    >
      {if @label, do: @label, else: render_slot(@inner_block)}
      <.icon :if={styled?(@style)} name="remix-external-link-line" class="w-4 h-4" />
    </button>
    """
  end

  # Private

  defp styled?("link"), do: true
  defp styled?("delete"), do: true
  defp styled?("sensitive"), do: true
  defp styled?(_), do: false

  defp link_class("link", true), do: "pc-link--styled__disabled"
  defp link_class("delete", true), do: "pc-link--styled__disabled"
  defp link_class("sensitive", true), do: "pc-link--styled__disabled"
  defp link_class("link", false), do: "pc-link--styled"
  defp link_class("delete", false), do: "pc-link--delete"
  defp link_class("sensitive", false), do: "pc-link--sensitive"
  defp link_class(_, _), do: nil
end
