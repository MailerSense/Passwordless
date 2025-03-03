defmodule PasswordlessWeb.DashboardComponents do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Components.PageComponents, only: [box: 1]
  import PasswordlessWeb.Components.Progress

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
          "hover:shadow-2 active:shadow-3 transition-all duration-150 ease-in-out",
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
          "p-6 rounded-lg flex flex-col gap-4",
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
        "p-6 bg-white dark:bg-slate-800",
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
            class="stroke-current text-slate-100 dark:text-slate-700"
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
      shadow_class="shadow-1"
      {@rest}
    >
      <div class="grid grid-cols-1 sm:grid-cols-3 divide-y sm:divide-y-0 sm:divide-x divide-slate-200 dark:divide-slate-700">
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
              <.progress max={max} class="flex-grow" value={value} color={color} />
          <% end %>
        </.a>
      </div>
      <div class="flex p-6 gap-6 items-center flex-wrap">
        <div :for={item <- @legend} class="flex gap-2 items-center">
          <span class={["w-4 h-2 rounded-full", item.color]}></span>
          <p class="text-slate-600 dark:text-slate-300 text-xs font-semibold">{item.label}</p>
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
          <h3 class="text-slate-900 dark:text-white text-2xl font-bold leading-6">
            {@value}
          </h3>
        </div>
      </div>
      <div class="flex items-center gap-1">
        <.icon name="custom-rise-line" class={["w-4 h-4", @change_class, @change_icon_class]} />
        <span class={["text-xs font-bold", @change_class]}>{"#{@change_symbol}#{@change}"}</span>
        <span class="text-slate-500 dark:text-slate-400 text-xs font-normal">
          change since last period
        </span>
      </div>
    </article>
    """
  end
end
