defmodule PasswordlessWeb.Components.DataTable do
  @moduledoc """
  Render your data with ease. Uses Flop under the hood: https://github.com/woylie/flop
  """

  use Phoenix.Component
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Badge
  import PasswordlessWeb.Components.Field
  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Pagination
  import PasswordlessWeb.Components.Table
  import PasswordlessWeb.Components.Tabs

  alias PasswordlessWeb.Components.DataTable.Cell
  alias PasswordlessWeb.Components.DataTable.Filter
  alias PasswordlessWeb.Components.DataTable.FilterSet
  alias PasswordlessWeb.Components.DataTable.Header

  attr :size, :string, default: "md", values: ["sm", "md", "lg", "xl", "wide"], doc: "table sizes"
  attr :meta, Flop.Meta, required: true
  attr :items, :list, required: true
  attr :title, :string, default: nil
  attr :title_func, {:fun, 1}, default: nil
  attr :class, :string, default: nil, doc: "CSS class to add to the table"
  attr :shadow_class, :string, default: "shadow-2", doc: "CSS class to add to the table"
  attr :base_url_params, :map, required: false

  attr :form_target, :string,
    default: nil,
    doc:
      "form_target allows you to target a specific live component for the close event to go to. eg: form_target={@myself}"

  attr :variant, :string,
    default: "solid",
    values: ["solid", "outline"],
    doc: "table variant"

  attr :switch_items, :list, default: [], doc: "Items for the switch field"

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
    attr :body_class, :string
    attr :field, :atom
    attr :sortable, :boolean
    attr :switchable, :boolean
    attr :searchable, :boolean
    attr :filterable, :list
    attr :date_format, :string
    attr :step, :float

    attr :renderer, :atom,
      values: [:plaintext, :checkbox, :date, :datetime, :money],
      doc: "How do you want your value to be rendered?"

    attr :actions, :boolean, doc: "Whether this is the actions column"
    attr :align_right, :boolean, doc: "Aligns the column to the right"
  end

  slot :actions, required: false
  slot :if_empty, required: false

  def data_table(assigns) do
    filter_changeset = build_filter_changeset(assigns.col, assigns.meta.flop)
    assigns = assign(assigns, filter_changeset: filter_changeset)

    assigns =
      assigns
      |> assign(:filtered?, Enum.any?(assigns.meta.flop.filters, fn x -> x.value end))
      |> assign(
        :search_field,
        Enum.find_value(assigns.col, fn
          %{searchable: true, field: field} -> field
          _ -> nil
        end)
      )
      |> assign(
        :switch_field,
        Enum.find_value(assigns.col, fn
          %{switchable: true, field: field} -> field
          _ -> nil
        end)
      )
      |> assign(:col, Enum.reject(assigns.col, fn col -> col[:searchable] end))
      |> assign_new(:filter_changeset, fn -> FilterSet.changeset(%FilterSet{}) end)
      |> assign_new(:base_url_params, fn -> %{} end)
      |> assign_new(:id, fn -> "data-table-#{:rand.uniform(10_000_000) + 1}" end)

    ~H"""
    <.form
      :let={filter_form}
      id="data-table-form"
      as={:filters}
      for={@filter_changeset}
      phx-change="update_filters"
      phx-submit="update_filters"
      {form_assigns(@form_target)}
    >
      <.table_search_bar
        :if={@search_field || @switch_field}
        meta={@meta}
        form={filter_form}
        switch_field={@switch_field}
        search_field={@search_field}
        switch_items={@switch_items}
      />
      <div class={["pc-table__wrapper", "pc-data-table__wrapper", @shadow_class, @class]}>
        <.table_header
          :if={Util.present?(@title) or Util.present?(@title_func)}
          meta={@meta}
          title={@title}
          title_func={@title_func}
        />
        <div class="pc-data-table">
          <.table>
            <thead class="pc-table__thead-striped">
              <.tr>
                <%= for col <- @col do %>
                  <%= if col[:actions] && @actions do %>
                    <.th class={[col[:class], "pc-table__th-#{@size}"]}>
                      <div class="flex justify-end gap-1" />
                    </.th>
                  <% else %>
                    <Header.render
                      meta={@meta}
                      column={col}
                      class={"pc-table__th--#{@size}"}
                      actions={@actions}
                      no_results?={@items == []}
                      base_url_params={@base_url_params}
                    />
                  <% end %>
                <% end %>
              </.tr>
            </thead>
            <tbody>
              <%= if @items == [] do %>
                <.tr>
                  <td class="pc-table__td--only" colspan={length(@col)}>
                    {if Util.present?(@if_empty), do: render_slot(@if_empty), else: "No results"}
                  </td>
                </.tr>
              <% end %>

              <.tr :for={item <- @items} class="pc-table__tr-striped">
                <.td
                  :for={col <- @col}
                  class={[
                    if(col[:align_right], do: "text-right"),
                    if(col[:actions], do: "flex justify-end gap-1"),
                    col[:body_class]
                  ]}
                >
                  <%= cond do %>
                    <% col[:actions] && @actions -> %>
                      {render_slot(@actions, item)}
                    <% col[:inner_block] -> %>
                      {render_slot(col, item)}
                    <% true -> %>
                      <Cell.render column={col} item={item} />
                  <% end %>
                </.td>
              </.tr>
            </tbody>
          </.table>
        </div>

        <%= if @meta.total_pages > 1 do %>
          <div class="pc-table__pagination">
            <.pagination
              path={
                @meta
                |> build_url_query(Map.merge(@base_url_params, %{page: ":page"}))
                |> String.replace("%3Apage", ":page")
              }
              link_type="live_patch"
              total_pages={@meta.total_pages}
              current_page={@meta.current_page}
            />
          </div>
        <% end %>
      </div>
    </.form>
    """
  end

  def build_url_query(meta, query_params) do
    "?" <> Plug.Conn.Query.encode(build_params(meta, query_params))
  end

  attr :id, :string, required: true
  attr :size, :string, default: "md", values: ["sm", "md", "lg"], doc: "table sizes"
  attr :meta, Flop.Meta, required: true
  attr :items, :any, required: true
  attr :title, :string, default: nil
  attr :class, :string, default: nil, doc: "CSS class to add to the table"
  attr :shadow_class, :string, default: "shadow-2", doc: "CSS class to add to the table"
  attr :finished, :boolean, default: false

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
    attr :body_class, :string
    attr :field, :atom
    attr :filterable, :list
    attr :date_format, :string
    attr :step, :float

    attr :renderer, :atom,
      values: [:plaintext, :checkbox, :date, :datetime, :money],
      doc: "How do you want your value to be rendered?"

    attr :actions, :boolean, doc: "Whether this is the actions column"
    attr :align_right, :boolean, doc: "Aligns the column to the right"
  end

  slot :header
  slot :actions, required: false
  slot :if_empty, required: false

  def stream_table(assigns) do
    ~H"""
    <div class={["pc-table__wrapper", "pc-stream-table__wrapper", @shadow_class, @class]}>
      <%= if Util.present?(@header) do %>
        {render_slot(@header)}
      <% end %>
      <.table_header :if={@title} title={@title} />
      <.table>
        <thead class="pc-table__thead-striped">
          <.tr>
            <%= for col <- @col do %>
              <%= if col[:actions] && @actions do %>
                <.th class={col[:class]}>
                  <div class="flex justify-end gap-1" />
                </.th>
              <% else %>
                <Header.render
                  meta={@meta}
                  class={"pc-table__th--#{@size}"}
                  column={col}
                  actions={@actions}
                  base_url_params={nil}
                />
              <% end %>
            <% end %>
          </.tr>
        </thead>
        <tbody id={@id} phx-update="stream" phx-viewport-bottom={!@finished && "load_more"}>
          <.tr class="only:block hidden">
            <td class="pc-table__td--only" colspan={length(@col)}>
              {if Util.present?(@if_empty), do: render_slot(@if_empty), else: "No results"}
            </td>
          </.tr>
          <.tr :for={{id, item} <- @items} id={id} class="pc-table__tr-striped">
            <.td
              :for={col <- @col}
              class={[
                if(col[:align_right], do: "text-right"),
                if(col[:actions], do: "flex justify-end gap-1"),
                col[:body_class]
              ]}
            >
              <%= cond do %>
                <% col[:actions] && @actions -> %>
                  {render_slot(@actions, item)}
                <% col[:inner_block] -> %>
                  {render_slot(col, item)}
                <% true -> %>
                  <Cell.render column={col} item={item} />
              <% end %>
            </.td>
          </.tr>
        </tbody>
      </.table>
    </div>
    """
  end

  attr :id, :string
  attr :size, :string, default: "md", values: ["sm", "md", "lg"], doc: "table sizes"
  attr :items, :any, required: true
  attr :title, :string, default: nil
  attr :class, :string, default: nil, doc: "CSS class to add to the table"
  attr :shadow_class, :string, default: "shadow-2", doc: "CSS class to add to the table"

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
    attr :body_class, :string
    attr :field, :atom
    attr :filterable, :list
    attr :date_format, :string
    attr :step, :float

    attr :renderer, :atom,
      values: [:plaintext, :checkbox, :date, :datetime, :money],
      doc: "How do you want your value to be rendered?"

    attr :actions, :boolean, doc: "Whether this is the actions column"
    attr :align_right, :boolean, doc: "Aligns the column to the right"
  end

  slot :actions, required: false
  slot :if_empty, required: false

  def simple_table(assigns) do
    assigns =
      assign_new(assigns, :id, fn -> "simple-table-#{:rand.uniform(10_000_000) + 1}" end)

    ~H"""
    <div class={["pc-table__wrapper", "pc-data-table__wrapper", @shadow_class, @class]}>
      <.table_header :if={@title} title={@title} />
      <.table class="pc-data-table">
        <thead class="pc-table__thead-striped">
          <.tr>
            <%= for col <- @col do %>
              <%= if col[:actions] && @actions do %>
                <.th class={col[:class]}>
                  <div class="flex justify-end gap-1" />
                </.th>
              <% else %>
                <Header.render
                  meta={%Flop.Meta{}}
                  class={"pc-table__th--#{@size}"}
                  column={col}
                  actions={@actions}
                  base_url_params={nil}
                />
              <% end %>
            <% end %>
          </.tr>
        </thead>
        <tbody>
          <%= if @items == [] do %>
            <.tr>
              <td class="pc-table__td--only" colspan={length(@col)}>
                {if Util.present?(@if_empty), do: render_slot(@if_empty), else: "No results"}
              </td>
            </.tr>
          <% end %>

          <.tr :for={item <- @items}>
            <.td
              :for={col <- @col}
              class={[
                if(col[:align_right], do: "text-right"),
                if(col[:actions], do: "flex justify-end gap-1"),
                col[:body_class]
              ]}
            >
              <%= cond do %>
                <% col[:actions] && @actions -> %>
                  {render_slot(@actions, item)}
                <% col[:inner_block] -> %>
                  {render_slot(col, item)}
                <% true -> %>
                  <Cell.render column={col} item={item} />
              <% end %>
            </.td>
          </.tr>
        </tbody>
      </.table>
    </div>
    """
  end

  # Private

  attr :meta, Flop.Meta, default: nil
  attr :title, :string, default: nil
  attr :title_func, {:fun, 1}, default: nil

  defp table_header(assigns) do
    assigns =
      case assigns[:title_func] do
        fun when is_function(fun, 1) -> assign(assigns, :title, fun.(assigns[:meta]))
        nil -> assigns
      end

    ~H"""
    <div class="px-6 py-5 flex items-center gap-4">
      <div class="flex items-center gap-2">
        <h3 class="text-lg font-medium text-slate-900 dark:text-white">
          {@title}
        </h3>
        <.badge
          :if={Util.present?(@meta)}
          size="sm"
          color="primary"
          label={Passwordless.Locale.Number.to_string!(@meta.total_count)}
        />
      </div>
    </div>
    """
  end

  attr :form, :map, default: nil
  attr :meta, Flop.Meta, required: true
  attr :title, :string, default: nil
  attr :switch_field, :atom, default: nil
  attr :search_field, :atom, default: nil
  attr :switch_items, :list, default: []

  defp table_search_bar(assigns) do
    ~H"""
    <div class={[
      "flex items-center justify-between gap-3",
      "pb-6"
    ]}>
      <.inputs_for :let={f2} field={@form[:filters]}>
        <%= if Phoenix.HTML.Form.input_value(f2, :field) == @switch_field do %>
          <.tab_menu
            mode="form"
            field={f2[:value]}
            name_field={f2[:field]}
            menu_items={@switch_items}
            current_tab={:all}
            variant="buttons"
          />
        <% end %>

        <%= if Phoenix.HTML.Form.input_value(f2, :field) == @search_field do %>
          <div class="flex items-center gap-3">
            <.field field={f2[:field]} type="hidden" />
            <.field
              icon="custom-search"
              field={f2[:value]}
              class="md:min-w-[400px] lg:min-w-[500px]"
              label=""
              phx-debounce="100"
              wrapper_class="!mb-0"
              placeholder="Search"
            />

            <button
              class={[
                "h-[46px]",
                "bg-white dark:bg-transparent select-none",
                "text-sm font-semibold text-slate-700 dark:text-slate-200",
                "flex items-center rounded-lg px-4 py-2.5 bg-white",
                "border border-slate-300 dark:border-slate-600 gap-2 shadow-m2",
                "transition duration-150 ease-in-out",
                "hover:text-slate-900 hover:bg-slate-50 focus:bg-slate-100 focus:text-slate-900 active:bg-slate-200 dark:bg-background-900 dark:text-white dark:hover:bg-background-800 dark:active:bg-background-900"
              ]}
              type="button"
              phx-click="clear_filters"
            >
              <.icon name="remix-filter-3-line" class="w-5 h-5" />
              {gettext("Clear")}
            </button>
          </div>
        <% end %>
      </.inputs_for>
    </div>
    """
  end

  defp to_query(%Flop{filters: filters} = flop, opts) do
    filter_map =
      filters
      |> Stream.filter(fn filter -> filter.value != nil end)
      |> Stream.with_index()
      |> Map.new(fn {filter, index} ->
        {index, Map.from_struct(filter)}
      end)

    default_limit = Flop.get_option(:default_limit, opts)
    default_order = Flop.get_option(:default_order, opts)

    []
    |> maybe_put(:offset, flop.offset, 0)
    |> maybe_put(:page, flop.page, 1)
    |> maybe_put(:after, flop.after)
    |> maybe_put(:before, flop.before)
    |> maybe_put(:limit, flop.limit, default_limit)
    |> maybe_put(:first, flop.first, default_limit)
    |> maybe_put(:last, flop.last, default_limit)
    |> maybe_put_order_params(flop, default_order)
    |> maybe_put(:filters, filter_map)
  end

  defp maybe_put(params, key, value, default \\ nil)
  defp maybe_put(keywords, _, nil, _), do: keywords
  defp maybe_put(keywords, _, [], _), do: keywords
  defp maybe_put(keywords, _, map, _) when map == %{}, do: keywords

  # It's not enough to avoid setting (initially), we need to remove any existing value
  defp maybe_put(keywords, key, val, val), do: Keyword.delete(keywords, key)

  defp maybe_put(keywords, key, value, _), do: Keyword.put(keywords, key, value)

  # Puts the order params of a into a keyword list only if they don't match the
  # defaults passed as the last argument.
  defp maybe_put_order_params(params, %{order_by: order_by, order_directions: order_directions}, %{
         order_by: order_by,
         order_directions: order_directions
       }),
       do: params

  defp maybe_put_order_params(params, %{order_by: order_by, order_directions: order_directions}, _) do
    params
    |> maybe_put(:order_by, order_by)
    |> maybe_put(:order_directions, order_directions)
  end

  defp build_filter_changeset(columns, flop) do
    filters =
      Enum.reduce(columns, [], fn col, acc ->
        if col[:filterable] do
          default_op = List.first(col.filterable)
          flop_filter = Enum.find(flop.filters, &(&1.field == col.field))

          filter = %Filter{
            field: col.field,
            op: (flop_filter && flop_filter.op) || default_op,
            value: (flop_filter && flop_filter.value) || nil
          }

          [filter | acc]
        else
          acc
        end
      end)

    filter_set = %FilterSet{filters: filters}
    FilterSet.changeset(filter_set)
  end

  def build_params(%{flop: flop, opts: opts}, query_params) do
    params =
      Keyword.new(query_params, fn {k, v} ->
        k = if Kernel.is_bitstring(k), do: String.to_atom(k), else: k
        {k, v}
      end)

    flop_params = to_query(flop, opts)

    params ++ flop_params
  end

  @doc """
  Use this to build a query when the filters have changed. Pass a flop and the params from the "update_filters" event.
  """
  def build_filter_params(meta, filter_params \\ %{}) do
    meta
    |> build_params(filter_params)
    |> Keyword.put(:page, "1")
  end

  def build_filter_params(meta, base_url_params, filter_params) do
    params = Map.merge(base_url_params, filter_params)

    build_filter_params(meta, params)
  end

  def update_filter_params(meta, filter_params \\ %{}) do
    meta
    |> build_params(filter_params)
    |> Keyword.put_new(:page, "1")
  end

  @doc """
  Wrapper around Flop.validate_and_run/3
  """
  def search(queryable, flop_or_params, opts \\ []) do
    Flop.validate_and_run!(queryable, flop_or_params, opts)
  end

  # Private

  defp form_assigns(nil), do: %{}
  defp form_assigns(target), do: %{"phx-target": target}
end
