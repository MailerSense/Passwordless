defmodule PasswordlessWeb.Components.Container do
  @moduledoc false
  use Phoenix.Component

  attr(:max_width, :string,
    default: "xl",
    values: ["sm", "md", "lg", "xl", "full"],
    doc: "sets container max-width"
  )

  attr(:class, :any, default: "", doc: "CSS class for container")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def container(assigns) do
    ~H"""
    <section {@rest} class={["pc-container pc-container--#{@max_width}", @class]}>
      {render_slot(@inner_block)}
    </section>
    """
  end
end
