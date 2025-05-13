defmodule PasswordlessWeb.Components.DataTable do
  @moduledoc """
  Render your data with ease. Uses Flop under the hood: https://github.com/woylie/flop
  """

  use Phoenix.Component
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Badge
  import PasswordlessWeb.Components.Field
  import PasswordlessWeb.Components.Pagination
  import PasswordlessWeb.Components.Table

  alias PasswordlessWeb.Components.DataTable.Cell
  alias PasswordlessWeb.Components.DataTable.Filter
  alias PasswordlessWeb.Components.DataTable.FilterSet
  alias PasswordlessWeb.Components.DataTable.Header
  alias PasswordlessWeb.Components.Icon

  attr :id, :string
  attr :size, :string, default: "md", values: ["sm", "md", "lg", "xl", "wide"], doc: "table sizes"
  attr :meta, Flop.Meta, required: true
  attr :items, :list, required: true
  attr :title, :string, default: nil
  attr :title_func, {:fun, 1}, default: nil
  attr :class, :string, default: nil, doc: "CSS class to add to the table"
  attr :search_placeholder, :string, default: "Search"

  attr :wrapper_class, :any,
    default: "pc-table__wrapper pc-data-table__wrapper",
    doc: "CSS class to add to the table"

  attr :base_url_params, :map, required: false
  attr :show_clear_button, :boolean, default: true

  attr :form_target, :string,
    default: nil,
    doc:
      "form_target allows you to target a specific live component for the close event to go to. eg: form_target={@myself}"

  attr :variant, :string,
    default: "solid",
    values: ["solid", "outline"],
    doc: "table variant"

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
    attr :body_class, :string
    attr :field, :atom
    attr :sortable, :boolean
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
  slot :header_actions, required: false
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
      |> assign(:col, Enum.reject(assigns.col, fn col -> col[:searchable] end))
      |> assign_new(:filter_changeset, fn -> FilterSet.changeset(%FilterSet{}) end)
      |> assign_new(:base_url_params, fn -> %{} end)
      |> assign_new(:id, fn -> Util.id("data-table") end)

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
      <section class={[@wrapper_class, @class]}>
        <div
          :if={@search_field}
          class="flex items-center justify-between gap-3 p-6 bg-slate-50 dark:bg-transparent border-b border-slate-200 dark:border-slate-700/30"
        >
          <.table_search_bar
            meta={@meta}
            form={filter_form}
            search_field={@search_field}
            search_placeholder={@search_placeholder}
            show_clear_button={@show_clear_button}
          />
          {render_slot(@header_actions)}
        </div>
        <.table_header :if={Util.present?(@title)} meta={@meta} title={@title} />
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
                <.tr class="pc-table__tr-striped">
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
      </section>
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
  attr :count, :integer, default: nil
  attr :subtitle, :string, default: nil
  attr :badge, :string, default: nil
  attr :head, :boolean, default: true
  attr :class, :string, default: nil, doc: "CSS class to add to the table"
  attr :finished, :boolean, default: false
  attr :base_url_params, :map, required: false

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

  def stream_table(assigns) do
    filter_changeset = build_filter_changeset(assigns.col, assigns.meta.flop)
    assigns = assign(assigns, filter_changeset: filter_changeset)

    assigns =
      assigns
      |> assign(:filtered?, Enum.any?(assigns.meta.flop.filters, fn x -> x.value end))
      |> assign(:col, Enum.reject(assigns.col, fn col -> col[:searchable] end))
      |> assign_new(:filter_changeset, fn -> FilterSet.changeset(%FilterSet{}) end)
      |> assign_new(:base_url_params, fn -> %{} end)

    ~H"""
    <section class={[
      "pc-table__wrapper",
      "pc-stream-table__wrapper",
      @class,
      unless(@finished, do: "pb-[calc(200vh)]")
    ]}>
      <.table_header :if={@title} count={@count} badge={@badge} title={@title} subtitle={@subtitle} />
      <.table>
        <thead :if={@head} class="pc-table__thead-striped">
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
                  no_results?={@finished}
                  base_url_params={@base_url_params}
                />
              <% end %>
            <% end %>
          </.tr>
        </thead>
        <tbody id={@id} phx-update="stream" phx-viewport-bottom={!@finished && "load_more"}>
          <.tr
            :for={{id, item} <- @items}
            id={id}
            class="pc-table__tr-striped"
            phx-mounted={
              Phoenix.LiveView.JS.transition(
                {"transition ease-in-out duration-200", "opacity-0 translate-y-2",
                 "opacity-100 translate-y-0"},
                time: 200
              )
            }
          >
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
          <.tr class="pc-table__tr-striped only:block hidden">
            <td class="pc-table__td--only" colspan={length(@col)}>
              {if Util.present?(@if_empty), do: render_slot(@if_empty), else: "No results"}
            </td>
          </.tr>
        </tbody>
      </.table>
    </section>
    """
  end

  attr :id, :string
  attr :size, :string, default: "md", values: ["sm", "md", "lg"], doc: "table sizes"
  attr :items, :any, required: true
  attr :count, :integer, default: nil
  attr :title, :string, default: nil
  attr :class, :string, default: nil, doc: "CSS class to add to the table"

  attr :wrapper_class, :any,
    default: "pc-table__wrapper pc-data-table__wrapper",
    doc: "CSS class to add to the table"

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
    assigns = assign_new(assigns, :id, fn -> Util.id("simple-table") end)

    ~H"""
    <section class={[@wrapper_class, @class]}>
      <.table_header :if={@title} title={@title} count={@count} />
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
            <.tr class="pc-table__tr-striped">
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
    </section>
    """
  end

  # Private

  attr :meta, Flop.Meta, default: nil
  attr :badge, :string, default: nil
  attr :count, :integer, default: nil
  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil

  defp table_header(assigns) do
    assigns =
      cond do
        Util.present?(assigns[:badge]) ->
          assigns

        Util.present?(assigns[:count]) ->
          assign(assigns, :badge, Passwordless.Locale.Number.to_string!(assigns[:count]))

        Util.present?(assigns[:meta]) ->
          assign(
            assigns,
            :badge,
            Passwordless.Locale.Number.to_string!(assigns[:meta].total_count)
          )

        true ->
          assigns
      end

    ~H"""
    <header class={[
      "p-6 flex items-center justify-between gap-4"
    ]}>
      <.div_wrapper class="flex items-center gap-2" wrap={Util.present?(@badge)}>
        <h1 class="text-lg font-semibold text-slate-900 dark:text-white">
          {@title}
        </h1>
        <.badge :if={Util.present?(@badge)} size="sm" color="primary" label={@badge} />
      </.div_wrapper>
    </header>
    """
  end

  attr :form, :map, default: nil
  attr :meta, Flop.Meta, required: true
  attr :search_field, :atom, default: nil
  attr :search_placeholder, :string, default: "Search"
  attr :show_clear_button, :boolean, default: true

  defp table_search_bar(assigns) do
    ~H"""
    <div class="grow flex items-end justify-between gap-3">
      <.inputs_for :let={f2} field={@form[:filters]}>
        <%= if Phoenix.HTML.Form.input_value(f2, :field) == @search_field do %>
          <div class="flex items-center gap-3">
            <.field field={f2[:field]} type="hidden" />
            <.field
              icon="custom-search"
              type="search"
              field={f2[:value]}
              class="lg:min-w-[350px] xl:min-w-[400px] h-12"
              label={gettext("Search")}
              label_sr_only={true}
              clearable={true}
              wrapper_class="mb-0!"
              placeholder={@search_placeholder}
            />
          </div>
        <% end %>
      </.inputs_for>

      <button
        :if={@show_clear_button}
        class="shrink-0 inline-flex justify-start items-center gap-2 text-slate-700 dark:text-slate-200"
        phx-click="clear_filters"
      >
        <Icon.icon name="remix-close-circle-line" class="w-[18px] h-[18px]" />
        <span class="text-xs font-semibold">
          Clear filters
        </span>
      </button>
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
