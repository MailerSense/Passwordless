defmodule PasswordlessWeb.Components.Typography do
  @moduledoc """
  Everything related to text. Headings, paragraphs and links
  """

  use Phoenix.Component

  attr(:class, :any, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:normal_tracking, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h1(assigns) do
    ~H"""
    <h1
      class={get_heading_classes("pc-h1", @class, @color_class, @normal_tracking, @no_margin)}
      {@rest}
    >
      {render_slot(@inner_block) || @label}
    </h1>
    """
  end

  attr(:class, :any, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:normal_tracking, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h2(assigns) do
    ~H"""
    <h2
      class={get_heading_classes("pc-h2", @class, @color_class, @normal_tracking, @no_margin)}
      {@rest}
    >
      {render_slot(@inner_block) || @label}
    </h2>
    """
  end

  attr(:class, :any, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:normal_tracking, :boolean, default: false, doc: "underlines a heading")
  attr(:font_class, :string, default: nil, doc: "adds a color class")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h3(assigns) do
    ~H"""
    <h3
      class={get_heading_classes("pc-h3", @class, @color_class, @normal_tracking, @no_margin)}
      {@rest}
    >
      {render_slot(@inner_block) || @label}
    </h3>
    """
  end

  attr(:class, :any, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:normal_tracking, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h4(assigns) do
    ~H"""
    <h4
      class={get_heading_classes("pc-h4", @class, @color_class, @normal_tracking, @no_margin)}
      {@rest}
    >
      {render_slot(@inner_block) || @label}
    </h4>
    """
  end

  attr(:class, :any, default: "", doc: "CSS class")
  attr(:label, :string, default: nil, doc: "label your heading")
  attr(:no_margin, :boolean, default: nil, doc: "removes margin from headings")
  attr(:normal_tracking, :boolean, default: false, doc: "underlines a heading")
  attr(:color_class, :string, default: nil, doc: "adds a color class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def h5(assigns) do
    ~H"""
    <h5
      class={get_heading_classes("pc-h5", @class, @color_class, @normal_tracking, @no_margin)}
      {@rest}
    >
      {render_slot(@inner_block) || @label}
    </h5>
    """
  end

  defp get_heading_classes(base_classes, custom_classes, color_class, normal_tracking, no_margin) do
    [
      base_classes,
      custom_classes,
      color_class || "pc-heading--color",
      if(normal_tracking, do: "tracking-normal", else: "tracking-tight"),
      !no_margin && "pc-heading--margin"
    ]
  end

  attr(:size, :string,
    default: "md",
    values: ["xs", "md", "lg"],
    doc: "slideover point of origin"
  )

  attr(:class, :any, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def p(assigns) do
    ~H"""
    <p class={["pc-text", "pc-text--#{@size}", @class]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr(:class, :any, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def prose(assigns) do
    ~H"""
    <article class={["prose dark:prose-invert", @class]} {@rest}>
      {render_slot(@inner_block)}
    </article>
    """
  end

  @doc """
  Usage:
      <.ul>
        <li>Item 1</li>
        <li>Item 2</li>
      </.ul>
  """

  attr(:class, :any, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def ul(assigns) do
    ~H"""
    <ul class={["pc-text", "list-disc list-inside", @class]} {@rest}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  Usage:
      <.ol>
        <li>Item 1</li>
        <li>Item 2</li>
      </.ol>
  """

  attr(:class, :any, default: "", doc: "CSS class")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def ol(assigns) do
    ~H"""
    <ol class={["pc-text", "list-decimal list-inside", @class]} {@rest}>
      {render_slot(@inner_block)}
    </ol>
    """
  end
end
