defmodule PasswordlessWeb.Components.Progress do
  @moduledoc false
  use Phoenix.Component

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])

  attr(:color, :string,
    default: "primary",
    values: ["primary", "primary-dark", "info", "success", "warning", "danger", "pink", "purple", "emerald", "slate"]
  )

  attr(:label, :boolean, default: false, doc: "labels your progress bar [xl only]")
  attr(:value, :integer, default: nil, doc: "adds a value to your progress bar")
  attr(:max, :integer, default: 100, doc: "sets a max value for your progress bar")
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)

  def progress(assigns) do
    ~H"""
    <%= if @label do %>
      <div class="flex gap-2 items-center">
        <div
          {@rest}
          class={["pc-progress--#{@size}", "pc-progress", "pc-progress--#{@color}", @class]}
        >
          <span
            class={["pc-progress__inner--#{@color}", "pc-progress__inner"]}
            style={"width: #{Float.round(@value/@max*100, 2)}%"}
          />
        </div>
        <span :if={@label} class="pc-progress__label">
          {trunc(Float.round(@value / @max * 100, 0))}%
        </span>
      </div>
    <% else %>
      <div {@rest} class={["pc-progress--#{@size}", "pc-progress", "pc-progress--#{@color}", @class]}>
        <span
          class={["pc-progress__inner--#{@color}", "pc-progress__inner"]}
          style={"width: #{Float.round(@value/@max*100, 2)}%"}
        />
      </div>
    <% end %>
    """
  end

  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])

  attr(:items, :list, default: [], doc: "adds a value to your progress bar")
  attr(:label, :float, default: nil, doc: "labels your progress bar [xl only]")
  attr(:max, :integer, default: 100, doc: "sets a max value for your progress bar")
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:rest, :global)

  def multi_progress(assigns) do
    ~H"""
    <.div_wrapper class="flex gap-2 items-center" wrap={Util.present?(@label)}>
      <div
        class={[
          "pc-progress--#{@size}",
          "pc-multi-progress",
          "pc-progress--primary",
          if(@label, do: "flex-grow"),
          @class
        ]}
        {@rest}
      >
        <span
          :for={item <- @items}
          class={[
            "pc-progress__inner--#{item.color}",
            "pc-multi-progress__inner",
            if(item[:rounded], do: "rounded-r-full", else: nil)
          ]}
          style={"width: #{Float.round((if @max > 0, do: item.value/@max*100, else: 0.0), 2)}%"}
        />
      </div>
      <span :if={Util.present?(@label)} class="pc-progress__label">
        {trunc(Float.round(@label * 100, 0))}%
      </span>
    </.div_wrapper>
    """
  end

  # Private

  attr :wrap, :boolean, default: false
  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp div_wrapper(assigns) do
    ~H"""
    <%= if @wrap do %>
      <div class={@class}>
        {render_slot(@inner_block)}
      </div>
    <% else %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end
end
