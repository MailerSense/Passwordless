defmodule PasswordlessWeb.CheckComponents do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Dropdown
  import PasswordlessWeb.Components.Field
  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Components.PageComponents, only: [box: 1]
  import PasswordlessWeb.Components.Pagination
  import PasswordlessWeb.Components.Progress
  import PasswordlessWeb.Components.Tabs

  alias PasswordlessWeb.Components.DataTable.Filter
  alias PasswordlessWeb.Components.DataTable.FilterSet

  attr :badge, :string, required: true
  attr :content, :string, required: true
  attr :class, :string, default: nil, doc: "CSS class"
  attr :rest, :global

  attr :to, :string, default: nil, doc: "link path"

  attr :link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]

  def simple_card(assigns) do
    ~H"""
    <%= if @to do %>
      <.a
        to={@to}
        link_type={@link_type}
        title={"#{@badge}: #{@content}"}
        {@rest}
        class={[
          "shadow-m2 hover:shadow-2 active:shadow-3 transition-all duration-150 ease-in-out",
          "border border-slate-200 dark:border-slate-700"
        ]}
      >
        <section class={[
          "p-6 rounded-lg flex flex-col gap-4",
          "bg-white dark:bg-slate-700/30",
          @class
        ]}>
          <badge class="text-slate-500 dark:text-slate-400 text-sm font-semibold leading-tight">
            {@badge}
          </badge>
          <h4 class="text-slate-900 dark:text-white text-2xl font-bold">
            {@content}
          </h4>
        </section>
      </.a>
    <% else %>
      <section
        class={[
          "p-6 rounded-lg shadow-m2 flex flex-col gap-4",
          "border border-slate-200 dark:border-slate-700",
          "bg-white dark:bg-slate-700/30",
          @class
        ]}
        {@rest}
      >
        <badge class="text-slate-500 dark:text-slate-400 text-sm font-semibold leading-tight">
          {@badge}
        </badge>
        <h4 class="text-slate-900 dark:text-white text-2xl font-bold">
          {@content}
        </h4>
      </section>
    <% end %>
    """
  end

  attr :to, :string, default: nil, doc: "link path"
  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :label, :string, required: true, doc: "labels your dropdown option"
  attr :value, :integer, required: true, doc: "labels your dropdown option"
  attr :value_max, :integer, required: true, doc: "labels your dropdown option"
  attr :color_class, :string, required: true, doc: "labels your dropdown option"

  attr :link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect", "button"]

  def single_stat(assigns) do
    ~H"""
    <.a
      to={@to}
      class={[
        "p-6 bg-white dark:bg-gray-800",
        "flex rounded-lg shadow-m2 justify-between",
        "hover:shadow-2 active:shadow-3 select-none",
        "transition duration-150 ease-in-out",
        "border border-slate-200 dark:border-slate-700",
        @class
      ]}
      link_type={@link_type}
    >
      <div class="flex flex-col justify-between">
        <badge class="text-slate-500 dark:text-slate-400 text-sm font-semibold leading-tight">
          {@label}
        </badge>
        <h4 class="text-slate-900 dark:text-white text-2xl font-bold">
          {Passwordless.Locale.Number.to_string!(@value)}
        </h4>
      </div>
      <div class="relative size-28 xl:size-32 2xl:size-36">
        <svg class="size-full -rotate-90" viewBox="0 0 36 36" xmlns="http://www.w3.org/2000/svg">
          <circle
            cx="18"
            cy="18"
            r="16"
            fill="none"
            class="stroke-current text-gray-100 dark:text-gray-700"
            stroke-width="3.5"
          >
          </circle>
          <circle
            cx="18"
            cy="18"
            r="16"
            fill="none"
            class={["stroke-current", @color_class]}
            stroke-width="3.5"
            stroke-dasharray="100"
            stroke-dashoffset={100 - trunc(Float.round(@value / @value_max * 100))}
            stroke-linecap="round"
          >
          </circle>
        </svg>
        <div class="absolute top-1/2 start-1/2 transform -translate-y-1/2 -translate-x-1/2">
          <span class={["text-center text-2xl font-semibold", @color_class]}>
            {trunc(Float.round(@value / @value_max * 100))}%
          </span>
        </div>
      </div>
    </.a>
    """
  end

  attr :class, :any, default: nil, doc: "any extra CSS class for the parent container"
  attr :legend, :list, default: [], doc: "labels your dropdown option"
  attr :items, :list, default: [], doc: "labels your dropdown option"
  attr :rest, :global

  def action_stat(assigns) do
    ~H"""
    <.box
      class={["flex flex-col divide-y divide-slate-200 dark:divide-slate-700 overflow-hidden", @class]}
      {@rest}
    >
      <div class="grid grid-cols-3 divide-x divide-slate-200 dark:divide-slate-700">
        <.a
          :for={item <- @items}
          to={item.to}
          link_type="live_redirect"
          class={[
            "flex flex-col gap-4 p-6",
            "transition duration-150 ease-in-out",
            "hover:bg-slate-50 dark:hover:bg-slate-800 active:bg-slate-100 dark:active:bg-slate-700"
          ]}
        >
          <badge class="text-slate-500 dark:text-slate-400 text-sm font-semibold leading-tight">
            {item.name}
          </badge>
          <h4 class="text-slate-900 dark:text-white text-2xl font-bold">
            {Passwordless.Locale.Number.to_string!(item.value)}
          </h4>
          <%= case item.progress do %>
            <% %{max: max, items: items} when is_list(items) -> %>
              <.multi_progress max={max} class="flex-grow" items={items} />
            <% %{max: max, value: value, color: color} -> %>
              <.progress
                max={item.progress.max}
                class="flex-grow"
                value={item.progress.value}
                color={item.progress.color}
              />
          <% end %>
        </.a>
      </div>
      <div class="flex p-6 gap-6 items-center">
        <div :for={item <- @legend} class="flex gap-2 items-center">
          <div class={["w-4 h-2 rounded-full", item.color]}></div>
          <p class="text-gray-600 dark:text-gray-300 text-xs font-semibold">{item.label}</p>
        </div>
      </div>
    </.box>
    """
  end

  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :label, :string, required: true, doc: "labels your dropdown option"
  attr :value, :float, required: true, doc: "labels your dropdown option"
  attr :change, :float, required: true, doc: "labels your dropdown option"
  attr :color_class, :string, required: true, doc: "labels your dropdown option"
  attr :rest, :global

  def change_stat(assigns) do
    assigns =
      assign(assigns, %{
        change_class: if(assigns[:change] > 0, do: "text-success-500", else: "text-danger-500"),
        change_symbol: if(assigns[:change] > 0, do: "+", else: "-"),
        change_icon_class: unless(assigns[:change] > 0, do: "rotate-180")
      })

    ~H"""
    <article
      class={[
        "p-6 bg-white dark:bg-slate-700/50 rounded-lg shadow-m2 flex flex-col gap-4",
        "border border-slate-200 dark:border-slate-700",
        @class
      ]}
      {@rest}
    >
      <div class="flex items-center gap-4">
        <div class={["w-1 h-full rounded-lg", @color_class]}></div>
        <div class="flex flex-col gap-4">
          <badge class="text-slate-500 dark:text-slate-400 text-sm font-semibold leading-tight">
            {@label}
          </badge>
          <h3 class="text-gray-900 dark:text-white text-2xl font-bold leading-6">
            {@value}
          </h3>
        </div>
      </div>
      <div class="flex items-center gap-1">
        <.icon name="custom-rise-line" class={["w-4 h-4", @change_class, @change_icon_class]} />
        <span class={["text-xs font-bold", @change_class]}>{"#{@change_symbol}#{@change}"}</span>
        <span class="text-gray-500 dark:text-gray-400 text-xs font-normal">
          change since last period
        </span>
      </div>
    </article>
    """
  end

  attr :to, :string, required: true
  attr :name, :string, required: true
  attr :icon, :string, required: true
  attr :class, :string, default: nil, doc: "the class to add to this element"
  attr :link_type, :string, default: "live_redirect"
  attr :rest, :global

  def integration_card(assigns) do
    ~H"""
    <.a to={@to} link_type={@link_type} title={@name}>
      <article {@rest} class={["pc-card__template", "group", @class]}>
        <div class="flex items-center justify-center rounded-lg min-h-[240px] bg-slate-100 dark:bg-slate-800">
          <.icon name={@icon} class="w-[124px] h-[124px]" />
        </div>

        <div class="flex flex-col gap-2 p-4">
          <h2 class="line-clamp-1 text-slate-900 dark:text-white text-2xl font-semibold">
            {@name}
          </h2>
          <span class="text-slate-500 dark:text-slate-400 text-xs font-semibold">
            {gettext("Last edited: %{date}",
              date: PasswordlessWeb.Helpers.format_date(DateTime.utc_now())
            )}
          </span>
        </div>
      </article>
    </.a>
    """
  end

  attr :to, :string, required: true
  attr :name, :string, required: true
  attr :icon, :string, required: true
  attr :class, :string, default: nil, doc: "the class to add to this element"
  attr :link_type, :string, default: "live_redirect"
  attr :rest, :global

  def data_card(assigns) do
    ~H"""
    <.a to={@to} link_type={@link_type} title={@name}>
      <article {@rest} class={["pc-card__template", "group", @class]}>
        <div class="flex items-center justify-center rounded-lg min-h-[240px] bg-slate-100 dark:bg-slate-800">
          <.icon name={@icon} class="w-[124px] h-[124px]" />
        </div>

        <div class="flex flex-col gap-2 p-4">
          <h2 class="line-clamp-1 text-slate-900 dark:text-white text-2xl font-semibold">
            {@name}
          </h2>
          <span class="text-slate-500 dark:text-slate-400 text-xs font-semibold">
            {gettext("Last edited: %{date}",
              date: PasswordlessWeb.Helpers.format_date(DateTime.utc_now())
            )}
          </span>
        </div>
      </article>
    </.a>
    """
  end

  attr :id, :string, required: true
  attr :state, :string, required: true
  attr :name, :string, required: true
  attr :website, :string, required: true
  attr :last_run_time, :string, required: true
  attr :show_sparkline, :boolean, default: true

  slot :actions, required: false

  def check_card(assigns) do
    assigns =
      assign(assigns, %{
        badge_icon_color:
          case assigns[:state] do
            :online -> "success"
            :warning -> "warning"
            :down -> "danger"
            _ -> nil
          end,
        badge_icon:
          case assigns[:state] do
            :online -> "remix-checkbox-circle-fill"
            :warning -> "remix-error-warning-fill"
            :down -> "remix-close-circle-fill"
            _ -> nil
          end,
        badge_text: Phoenix.Naming.humanize(assigns[:state])
      })

    combos = [
      {"remix-file-pdf-2-fill", "text-danger-500 dark:text-danger-400"},
      {"remix-file-excel-fill", "text-success-500 dark:text-success-400"},
      {"remix-file-word-fill", "text-blue-500 dark:text-blue-400"},
      {"remix-file-ppt-fill", "text-orange-500 dark:text-orange-400"},
      {"remix-file-image-fill", "text-fuchsia-500 dark:text-fuchsia-400"}
    ]

    assigns = assign_new(assigns, :combo, fn -> Enum.random(combos) end)

    ~H"""
    <article class={["pc-card", "pc-card--link", "group"]}>
      <.a class={["pc-card__image"]} to={~p"/app/agents/#{@id}/data"} link_type="live_redirect">
        <img
          src="https://scrapeway.com/img/services/scrapingbee-dash-logs.png"
          class="pc-card__image-image"
          loading="lazy"
        />
      </.a>
      <div class={["pc-card__content"]}>
        <div class="pc-card__heading-wrapper">
          <.icon name={elem(@combo, 0)} class={["pc-card__heading-icon", elem(@combo, 1)]} />
          <h2 class="pc-card__heading">
            {@name}
          </h2>

          <div class="ml-auto">
            <.dropdown placement="left">
              <:trigger_element>
                <.icon name="custom-more-dots" class="w-6 h-6 invisible group-hover:visible" />
              </:trigger_element>
              <.dropdown_menu_item link_type="live_redirect" to={~p"/app/agents/#{@id}/data"}>
                <.icon name="remix-pencil-line" class="w-6 h-6 shrink-0" />
                {gettext("Edit")}
              </.dropdown_menu_item>
              <.dropdown_menu_item link_type="live_patch" to={~p"/app/agents/#{@id}/delete"}>
                <.icon
                  name="remix-delete-bin-line"
                  class="w-6 h-6 shrink-0 text-red-600 dark:text-danger-400"
                />
                <span class="text-red-600 dark:text-danger-400">{gettext("Delete")}</span>
              </.dropdown_menu_item>
            </.dropdown>
          </div>
        </div>
      </div>
    </article>
    """
  end

  attr :meta, Flop.Meta, required: true
  attr :items, :list, required: true
  attr :title, :string, default: nil
  attr :class, :string, default: nil, doc: "CSS class to add to the table"
  attr :base_url_params, :map, required: false

  attr :menu_items, :list,
    required: true,
    doc: "list of maps with keys :name, :path, :label, :icon (atom)"

  slot :actions, required: false
  slot :if_empty, required: false

  def check_table(assigns) do
    filter_changeset =
      build_filter_changeset(
        [%{filterable: [:==], field: :search}, %{filterable: [:==], field: :state}],
        assigns.meta.flop
      )

    assigns = assign(assigns, filter_changeset: filter_changeset)

    assigns =
      assigns
      |> assign(:filtered?, Enum.any?(assigns.meta.flop.filters, fn x -> x.value end))
      |> assign_new(:filter_changeset, fn -> FilterSet.changeset(%FilterSet{}) end)
      |> assign_new(:base_url_params, fn -> %{} end)
      |> assign_new(:id, fn -> "check-table-#{:rand.uniform(10_000_000) + 1}" end)

    ~H"""
    <div id={@id} class={["flex flex-col gap-6", @class]}>
      <.form
        :let={filter_form}
        id="check-table-form"
        as={:filters}
        for={@filter_changeset}
        phx-change="update_filters"
        phx-submit="update_filters"
      >
        <div class="flex justify-between">
          <.inputs_for :let={f2} field={filter_form[:filters]}>
            <%= if Phoenix.HTML.Form.input_value(f2, :field) == :state do %>
              <.tab_menu
                mode="form"
                field={f2[:value]}
                name_field={f2[:field]}
                menu_items={@menu_items}
                current_tab={:all}
                variant="buttons"
              />
            <% end %>

            <%= if Phoenix.HTML.Form.input_value(f2, :field) == :search do %>
              <div class="flex items-center gap-3">
                <.field field={f2[:field]} type="hidden" />
                <.field
                  icon="custom-search"
                  field={f2[:value]}
                  class="sm:min-w-64 xl:min-w-[370px]"
                  label=""
                  phx-debounce="100"
                  wrapper_class="!mb-0"
                  placeholder="Search"
                />

                <button
                  class={[
                    "h-[44px]",
                    "bg-white dark:bg-transparent select-none",
                    "text-sm font-semibold text-slate-700 dark:text-slate-200",
                    "flex items-center rounded-lg px-4 py-2.5 bg-white",
                    "border border-slate-300 dark:border-slate-600 gap-2 shadow-m2",
                    "transition duration-150 ease-in-out",
                    "hover:text-slate-900 hover:bg-slate-50 focus:bg-slate-100 focus:text-slate-900 active:bg-slate-200 dark:bg-slate-900 dark:text-white dark:hover:bg-slate-800 dark:active:bg-slate-900"
                  ]}
                  phx-click="clear_filters"
                >
                  <.icon name="remix-filter-3-line" class="w-5 h-5" />
                  {gettext("Clear")}
                </button>
              </div>
            <% end %>
          </.inputs_for>
        </div>
      </.form>

      <div role="list" class="grid gap-4 grid-cols-1 md:grid-cols-2 xl:grid-cols-3">
        <%= if @items == [] do %>
          {if Util.present?(@if_empty), do: render_slot(@if_empty), else: "No results"}
        <% end %>

        <.check_card :for={check <- @items} {Map.from_struct(check)} />
      </div>

      <%= if @meta.total_pages > 1 do %>
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
      <% end %>
    </div>
    """
  end

  # Private

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

    FilterSet.changeset(%FilterSet{filters: filters})
  end

  defp apply_filters(filters, %Flop.Meta{} = meta, path)
       when is_map(filters) and map_size(filters) > 0 and is_binary(path) do
    path <> "?" <> Plug.Conn.Query.encode(build_params(meta, filters))
  end

  defp apply_filters(_filters, _meta, path) when is_binary(path), do: path

  def build_url_query(meta, query_params) do
    params = build_params(meta, query_params)

    "?" <> Plug.Conn.Query.encode(params)
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
end
