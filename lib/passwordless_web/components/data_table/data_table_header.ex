defmodule PasswordlessWeb.Components.DataTable.Header do
  @moduledoc false
  use Phoenix.Component

  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Components.Table

  def render(assigns) do
    index = order_index(assigns.meta.flop, assigns.column[:field])
    direction = order_direction(assigns.meta.flop.order_directions, index)

    assigns =
      assigns
      |> assign(:currently_ordered, index == 0)
      |> assign(:order_direction, direction)

    ~H"""
    <.th class={["align-top", @column[:class], @class]}>
      <%= if @column[:sortable] && !@no_results? do %>
        <.a
          to={order_link(@column, @meta, @currently_ordered, @order_direction, @base_url_params)}
          class={[
            "flex items-center gap-1",
            if(@column[:align_right], do: "justify-end"),
            if(@currently_ordered, do: "text-slate-900 dark:text-white")
          ]}
          link_type="live_patch"
        >
          {get_label(@column)}
          <.icon
            name={
              cond do
                @currently_ordered && @order_direction == :desc -> "remix-arrow-down-line"
                @currently_ordered && @order_direction == :asc -> "remix-arrow-up-line"
                true -> "remix-expand-up-down-line"
              end
            }
            class="h-4 w-4"
          />
        </.a>
      <% else %>
        <div class={if @column[:align_right], do: "text-right whitespace-nowrap"}>
          {get_label(@column)}
        </div>
      <% end %>
    </.th>
    """
  end

  def render_simple(assigns) do
    ~H"""
    <.th class={["align-top", @column[:class]]}>
      <div class={if @column[:align_right], do: "text-right whitespace-nowrap"}>
        {get_label(@column)}
      </div>
    </.th>
    """
  end

  # Private

  defp get_label(column) do
    case column[:label] do
      nil ->
        PhoenixHTMLHelpers.Form.humanize(column.field)

      label ->
        label
    end
  end

  defp order_link(column, meta, currently_ordered, order_direction, base_url_params) do
    params =
      Map.merge(base_url_params, %{
        order_by: [column.field],
        order_directions:
          cond do
            currently_ordered && order_direction == :desc -> [:asc]
            currently_ordered && order_direction == :asc -> [:desc]
            true -> [:asc]
          end
      })

    PasswordlessWeb.Components.DataTable.build_url_query(meta, params)
  end

  defp order_index(%Flop{order_by: nil}, _), do: nil

  defp order_index(%Flop{order_by: order_by}, field) do
    Enum.find_index(order_by, &(&1 == field))
  end

  defp order_direction(_, nil), do: nil
  defp order_direction(nil, _), do: :asc
  defp order_direction(directions, index), do: Enum.at(directions, index)
end
