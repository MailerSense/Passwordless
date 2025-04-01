defmodule PasswordlessWeb.DashboardComponents do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Avatar
  import PasswordlessWeb.Components.Badge
  import PasswordlessWeb.Components.Form
  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link
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
          "shadow-1 hover:shadow-2 active:shadow-3 transition-all duration-150 ease-in-out",
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
          "shadow-1 p-6 rounded-lg flex flex-col gap-4",
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
    assigns =
      assign(
        assigns,
        :grid_class,
        case Enum.count(assigns[:items]) do
          1 -> "lg:grid-cols-1"
          2 -> "lg:grid-cols-2"
          3 -> "lg:grid-cols-3"
          _ -> "lg:grid-cols-4"
        end
      )

    ~H"""
    <div class={["flex flex-col gap-6", @class]} {@rest}>
      <div class={[
        @grid_class,
        "grid grid-cols-1",
        "gap-6 lg:gap-0 lg:divide-x divide-slate-200 dark:divide-slate-700"
      ]}>
        <div
          :for={item <- @items}
          class={[
            "flex flex-col gap-4 lg:px-6",
            "lg:first:pl-0 lg:last:pr-0"
          ]}
        >
          <badge class="text-slate-500 dark:text-slate-400 text-sm font-semibold">
            {item.name}
          </badge>
          <h2 class="text-slate-900 dark:text-white text-2xl font-bold">
            {Util.number!(item.value)} {ngettext(
              "time",
              "times",
              item.value
            )}
          </h2>
          <%= case item.progress do %>
            <% %{max: max, items: items} when is_list(items) -> %>
              <.multi_progress max={max} items={items} />
            <% %{max: max, value: value, color: color} -> %>
              <.progress max={max} value={value} color={color} />
          <% end %>
        </div>
      </div>

      <div class="flex gap-6 items-center flex-wrap">
        <div :for={item <- @legend} class="flex gap-2 items-center">
          <span class={["w-4 h-2 rounded-full", item.color]}></span>
          <p class="text-slate-600 dark:text-slate-300 text-xs font-semibold">{item.label}</p>
        </div>
      </div>
    </div>
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

  attr :to, :string, default: nil, doc: "link path"
  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :name, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :preview, :string, required: true, doc: "any extra CSS class for the parent container"

  attr :link_type, :string,
    default: "a",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :rest, :global

  def email_preview(assigns) do
    assigns = assign_new(assigns, :id, fn -> Util.id("email-review") end)

    ~H"""
    <div class={["pc-form-field-wrapper", @class]} {@rest}>
      <.form_label>{gettext("Preview")}</.form_label>
      <.a
        to={@to}
        class="flex items-start justify-center bg-slate-100 rounded-lg dark:bg-slate-700/50 max-h-[280px] overflow-hidden"
        link_type={@link_type}
      >
        <iframe
          id={"html-preview-#{@id}"}
          src="about:blank"
          class="w-full origin-top h-lvh pointer-events-none"
          scrolling="no"
          data-source={"html-preview-data-#{@id}"}
        />
      </.a>
      <div
        id={"html-preview-data-#{@id}"}
        phx-hook="HTMLPreviewHook"
        class="hidden"
        data-iframe={"html-preview-#{@id}"}
      >
        {@preview}
      </div>
    </div>
    """
  end

  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :preview, :string, default: "", doc: "any extra CSS class for the parent container"

  attr :rest, :global

  def sms_preview(assigns) do
    ~H"""
    <div class={["pc-form-field-wrapper", @class]} {@rest}>
      <.form_label>{gettext("Preview")}</.form_label>

      <div class="flex flex-col gap-y-12 flex-auto shrink-0 p-4 bg-slate-100 rounded-lg dark:bg-slate-700/50">
        <div class="flex flex-row items-center max-w-md ml-4">
          <.avatar name="AU" size="md" color="success" class="shrink-0" />
          <div class="relative px-4 py-2 ml-3 text-sm bg-white shadow-0 dark:bg-slate-600 rounded-xl">
            <.unsafe_markdown content={@preview} class="text-black dark:text-white" />
          </div>
        </div>

        <div class="flex flex-row items-center grow w-full h-auto px-4">
          <div class="mr-4">
            <button
              type="button"
              id="microphone"
              class="size-[36px] flex items-center justify-center text-sm text-slate-600 bg-white rounded-full shadow-sm dark:text-white hover:bg-slate-100 ring-slate-300 dark:bg-slate-700 ring-1 dark:ring-slate-500 group dark:hover:bg-slate-600 active:ring-4 active:ring-blue-300 dark:focus:bg-slate-700 active:animate-pulse active:bg-red-400 dark:active:bg-red-500"
            >
              <.icon name="hero-microphone-solid" class="w-4 h-4" />
            </button>
          </div>
          <div class="grow" id="chat-box">
            <div class="relative w-full">
              <input
                id="chat-message"
                name="reply"
                value=""
                type="textarea"
                rows="1"
                class="flex w-full pl-4 border min-h-10 rounded-xl focus:outline-hidden border border-slate-300 dark:border-slate-600"
              />
            </div>
          </div>
          <div class="ml-4">
            <button
              type="submit"
              id="submit-button"
              class="size-[36px] flex items-center justify-center text-sm text-slate-600 rounded-full shadow-sm dark:text-white ring-slate-300 hover:bg-slate-100 focus:bg-white ring-1 dark:ring-slate-300 group dark:hover:bg-slate-400 bg-white dark:bg-transparent"
            >
              <.icon id="icon" name="hero-paper-airplane-solid" class={["w-4 h-4"]} />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :content, :string, required: true, doc: "The content to render as markdown."
  attr :class, :string, doc: "The class to apply to the rendered markdown.", default: ""

  def unsafe_markdown(assigns) do
    ~H"""
    <div class={[
      "prose dark:prose-invert prose-img:rounded-xl prose-img:mx-auto prose-a:text-primary-600 prose-a:dark:text-primary-300",
      @class
    ]}>
      {Phoenix.HTML.raw(
        Passwordless.MarkdownRenderer.to_html(@content, %Earmark.Options{
          code_class_prefix: "language-",
          escape: false
        })
      )}
    </div>
    """
  end

  attr :codes, :list, required: true, doc: "The content to render as markdown."
  attr :class, :string, doc: "The class to apply to the rendered markdown.", default: ""

  def recovery_codes(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
      <%= for backup_code <- @codes do %>
        <div class="flex items-center justify-center p-3 font-mono bg-slate-300 rounded-sm dark:bg-slate-700">
          <h4>
            <%= if backup_code.used_at do %>
              <del class="line-through">{backup_code.code}</del>
            <% else %>
              {backup_code.code}
            <% end %>
          </h4>
        </div>
      <% end %>
    </div>
    """
  end

  attr :badge, :string, default: nil
  attr :count, :integer, default: nil
  attr :title, :string, default: nil
  attr :action_link, :string, default: nil
  attr :action_title, :string, default: nil
  attr :action_link_type, :string, default: "live_patch"
  attr :rest, :global

  slot :inner_block

  def action_header(assigns) do
    assigns =
      cond do
        Util.present?(assigns[:badge]) ->
          assigns

        Util.present?(assigns[:count]) ->
          assign(assigns, :badge, Passwordless.Locale.Number.to_string!(assigns[:count]))

        true ->
          assigns
      end

    ~H"""
    <div
      class={[
        "px-6 py-5 flex items-center justify-between gap-4"
      ]}
      {@rest}
    >
      <div class="flex items-center gap-2">
        <h3 class="text-lg font-medium text-slate-900 dark:text-white">
          {@title}
        </h3>
        <.badge :if={Util.present?(@badge)} size="sm" color="primary" label={@badge} />
      </div>

      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :to, :string, required: true
  attr :icon, :string, required: true
  attr :class, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :link_type, :string, default: "live_redirect"
  attr :enabled, :boolean, required: true

  attr :color, :string,
    default: "blue",
    values: ["blue", "indigo", "purple", "slate"]

  def quick_action(assigns) do
    assigns =
      assign(assigns,
        badge_label: if(assigns[:enabled], do: gettext("Enabled"), else: gettext("Disabled")),
        badge_color: if(assigns[:enabled], do: "success", else: "gray")
      )

    ~H"""
    <.a
      to={@to}
      link_type={@link_type}
      class={[
        "flex flex-col items-center justify-center gap-4 px-6",
        "lg:first:pl-0 lg:last:pr-0",
        "transition duration-150 ease-in-out hover:bg-gray-50 focus:bg-gray-100 active:bg-gray-100 dark:hover:bg-gray-700 dark:focus:bg-gray-600 dark:active:bg-gray-600",
        @class
      ]}
    >
      <span class={["p-2 rounded-lg", "pc-quickadd--#{@color}-bg"]}>
        <.icon name={@icon} class={["w-8 h-8", "pc-quickadd--#{@color}-text"]} />
      </span>
      <div class="flex flex-col gap-1 items-center">
        <span class="text-base font-semibold leading-tight text-gray-900 dark:text-white">
          {@title}
        </span>
        <.badge size="sm" color={@badge_color} label={@badge_label} />
      </div>
    </.a>
    """
  end
end
