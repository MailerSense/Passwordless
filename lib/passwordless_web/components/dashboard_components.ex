defmodule PasswordlessWeb.DashboardComponents do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Avatar
  import PasswordlessWeb.Components.Badge
  import PasswordlessWeb.Components.Field
  import PasswordlessWeb.Components.Form
  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Components.PageComponents
  import PasswordlessWeb.Components.Progress
  import PasswordlessWeb.Components.Typography

  alias Passwordless.Accounts.User
  alias Passwordless.Locale.Number, as: NumberLocale

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
    <.box padded body_class="flex flex-col gap-4">
      <badge class="text-gray-500 dark:text-gray-400 text-sm font-semibold leading-tight">
        {@badge}
      </badge>
      <h4 class="text-gray-900 dark:text-white text-2xl font-bold">
        {@content}
      </h4>
    </.box>
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
        "border border-gray-200 dark:border-gray-700",
        @class
      ]}
      link_type={@link_type}
    >
      <div class="flex flex-col justify-between">
        <badge class="text-gray-500 dark:text-gray-400 text-sm font-semibold leading-tight">
          {@label}
        </badge>
        <h4 class="text-gray-900 dark:text-white text-2xl font-bold">
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
        "gap-6 lg:gap-0 lg:divide-x divide-gray-200 dark:divide-gray-700"
      ]}>
        <div
          :for={item <- @items}
          class={[
            "flex flex-col gap-4 lg:px-6",
            "lg:first:pl-0 lg:last:pr-0"
          ]}
        >
          <badge class="text-gray-500 dark:text-gray-400 text-sm font-semibold">
            {item.name}
          </badge>
          <h2 class="text-gray-900 dark:text-white text-2xl font-bold">
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
          <p class="text-gray-600 dark:text-gray-300 text-xs font-semibold">{item.label}</p>
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
        "p-6 bg-white dark:bg-gray-700/50 rounded-lg shadow-m2 flex flex-col gap-4",
        "border border-gray-200 dark:border-gray-700",
        @class
      ]}
      {@rest}
    >
      <div class="flex items-center gap-4">
        <div class={["w-1 h-full rounded-lg", @color_class]}></div>
        <div class="flex flex-col gap-4">
          <badge class="text-gray-500 dark:text-gray-400 text-sm font-semibold leading-tight">
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
      <.field_label>{gettext("Preview")}</.field_label>
      <.a
        to={@to}
        title={@name}
        class="flex items-start justify-center bg-gray-100 rounded-lg dark:bg-gray-700/50 max-h-[300px] shadow-m2 overflow-hidden"
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

  attr :variant, :string,
    default: "sms",
    values: ["sms", "whatsapp"]

  attr :rest, :global

  def sms_preview(assigns) do
    assigns =
      assign(
        assigns,
        whatsapp: assigns[:variant] == "whatsapp",
        bg_class:
          case assigns[:variant] do
            "sms" -> "bg-gray-100 dark:bg-gray-700/50"
            "whatsapp" -> "relative overflow-hidden"
          end,
        avatar_attrs: %{
          icon:
            case assigns[:variant] do
              "sms" -> "remix-whatsapp-fill"
              "whatsapp" -> "remix-whatsapp-fill"
            end,
          name:
            case assigns[:variant] do
              "sms" -> "AU"
              "whatsapp" -> nil
            end
        }
      )

    ~H"""
    <div class={["pc-form-field-wrapper", @class]} {@rest}>
      <.form_label>{gettext("Preview")}</.form_label>

      <div class={["flex flex-col gap-y-8 flex-auto shrink-0 p-4 rounded-lg shadow-m2", @bg_class]}>
        <img
          :if={@whatsapp}
          src={~p"/images/whatsapp_bg.png"}
          class="absolute top-0 left-0 w-full object-contain z-10"
        />

        <div class="flex flex-row items-center max-w-md ml-4 z-20">
          <.avatar {@avatar_attrs} size="md" color="success" class="shrink-0" />
          <div class="relative px-4 py-2 ml-3 text-sm bg-white shadow-0 dark:bg-gray-600 rounded-xl">
            <.p class="text-gray-900 dark:text-white">{Phoenix.HTML.raw(@preview)}</.p>
          </div>
        </div>

        <div class="flex flex-row items-center grow w-full h-auto px-4 z-20">
          <div class="mr-4">
            <button
              type="button"
              id="microphone"
              class="w-9 h-9 flex items-center justify-center text-sm text-gray-600 bg-white rounded-full shadow-sm dark:text-white hover:bg-gray-100 ring-gray-300 dark:bg-gray-700 ring-1 dark:ring-gray-500 group dark:hover:bg-gray-600 active:ring-4 active:ring-blue-300 dark:focus:bg-gray-700 active:animate-pulse active:bg-red-400 dark:active:bg-red-500"
            >
              <.icon name="remix-mic-fill" class="w-4 h-4" />
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
                class="flex w-full pl-4 border min-h-10 rounded-xl bg-white dark:bg-gray-700 focus:outline-hidden border border-gray-300 dark:border-gray-600"
              />
            </div>
          </div>
          <div class="ml-4">
            <button
              type="submit"
              id="submit-button"
              class="w-9 h-9 flex items-center justify-center text-sm text-gray-600 rounded-full shadow-sm dark:text-white ring-gray-300 hover:bg-gray-100 focus:bg-white ring-1 dark:ring-gray-500 group dark:hover:bg-gray-400 bg-white dark:bg-gray-700"
            >
              <.icon id="icon" name="remix-send-plane-2-fill" class={["w-4 h-4"]} />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :code, :string, required: true, doc: "any extra CSS class for the parent container"
  attr :rest, :global

  def totp_preview(assigns) do
    ~H"""
    <div class={["pc-form-field-wrapper", @class]} {@rest}>
      <.field_label>{gettext("Preview")}</.field_label>
      <div class="flex justify-center items-center bg-gray-100 rounded-lg dark:bg-gray-700/50 shadow-m2 p-6 gap-6">
        <div class="inline-block">
          {generate_qrcode(@code)}
        </div>
        <div class="flex flex-col gap-5 px-4 py-8 sm:px-0">
          <.p>
            {gettext("Or enter this secret into your two-factor authentication app:")}
          </.p>
          <div class="p-5 border-4 border-gray-300 border-dashed rounded-lg dark:border-gray-700">
            <div class="text-xl font-bold text-gray-900 dark:text-white" id="totp-secret">
              {format_secret(@code)}
            </div>
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
        Passwordless.Templating.Markdown.to_html(@content, %Earmark.Options{
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
        <div class="flex items-center justify-center p-3 font-mono bg-gray-300 rounded-sm dark:bg-gray-700">
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
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
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

  attr :id, :string
  attr :current_user, :map, default: nil
  attr :rest, :global

  def sentry_user_setter(%{current_user: %User{} = user} = assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> Util.id("copy-button") end)
      |> assign(
        user_id: user.id,
        username: user.name,
        email: user.email,
        org: if(user.current_org, do: user.current_org.id),
        app: if(user.current_app, do: user.current_app.id)
      )

    ~H"""
    <div
      id={@id}
      phx-hook="SetSentryUserHook"
      data-id={@user_id}
      data-username={@username}
      data-email={@email}
      data-org={@org}
      data-app={@app}
      {@rest}
    >
    </div>
    """
  end

  def sentry_user_setter(assigns) do
    ~H"""
    <div></div>
    """
  end

  attr :class, :any, default: nil, doc: "CSS class to add to the table"
  attr :rest, :global

  slot :inner_block, required: true

  def timeline_box(assigns) do
    ~H"""
    <div class={["flex gap-3", @class]} {@rest}>
      <div class="flex flex-col items-center gap-4">
        <.icon name="custom-play-circle" class={["w-5 h-5", "text-gray-300 dark:text-white/30"]} />
        <span class="w-[1px] border border-dashed border-gray-300 dark:border-white/30 grow mb-4">
        </span>
      </div>
      <div class="flex flex-col items-start gap-2 mb-10">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :items, :list, default: []
  attr :class, :any, default: nil

  def article_list(assigns) do
    ~H"""
    <div class={["flex flex-col gap-3", @class]} role="list">
      <div :for={item <- @items} class="flex items-center gap-4" role="listitem">
        <.icon name="custom-check-fancy" class="w-8 h-8 text-primary-500" />
        <.p>{Phoenix.HTML.raw(item)}</.p>
      </div>
    </div>
    """
  end

  attr :id, :string
  attr :to, :string, required: true
  attr :link_type, :string, default: "live_redirect"

  def live_indicator(assigns) do
    assigns = assign_new(assigns, :id, fn -> Util.id("live-indicator") end)

    ~H"""
    <.a
      id={@id}
      to={@to}
      class={[
        "flex items-center text-sm font-medium text-gray-900 dark:text-white gap-1.5"
      ]}
      link_type={@link_type}
      phx-hook="TippyHook"
      data-tippy-content={gettext("Users who performed an action in last 6 hours")}
      data-tippy-placement="bottom"
    >
      <span class="relative flex size-3">
        <span class="absolute inline-flex h-full w-full animate-ping rounded-full bg-success-400 opacity-75">
        </span>
        <span class="relative inline-flex size-3 rounded-full bg-success-500"></span>
      </span>
      207 users online
    </.a>
    """
  end

  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :label, :string, required: true, doc: "labels your dropdown option"
  attr :legend_color_class, :string, required: true, doc: "labels your dropdown option"
  attr :circle_color_class, :string, required: true, doc: "labels your dropdown option"
  attr :value, :integer, required: true, doc: "labels your dropdown option"
  attr :value_max, :integer, required: true, doc: "labels your dropdown option"

  def circle_stat(assigns) do
    ~H"""
    <.box class={["flex gap-6", @class]} padded>
      <div class="flex flex-col justify-between gap-4">
        <badge class="flex gap-2 items-center">
          <div class={["w-4 h-2 rounded-full", @legend_color_class]}></div>
          <p class="text-gray-600 dark:text-gray-300 text-xs font-semibold">{@label}</p>
        </badge>
        <h3 class="text-gray-900 dark:text-white text-xl xl:text-2xl font-bold">
          {NumberLocale.to_string!(@value)}
        </h3>
      </div>
      <div class="ml-auto relative size-24 xl:size-32">
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
            class={["stroke-current", @circle_color_class]}
            stroke-width="3.5"
            stroke-dasharray="100"
            stroke-dashoffset={
              100 - trunc(if @value_max > 0, do: Float.round(@value / @value_max * 100), else: 0.0)
            }
            stroke-linecap="round"
          >
          </circle>
        </svg>
        <div class="absolute top-1/2 start-1/2 transform -translate-y-1/2 -translate-x-1/2">
          <span class={["text-center text-xl xl:text-2xl font-semibold", @circle_color_class]}>
            {trunc(if @value_max > 0, do: Float.round(@value / @value_max * 100), else: 0.0)}%
          </span>
        </div>
      </div>
    </.box>
    """
  end

  def bar_stats(assigns) do
    ~H"""
    <.box body_class="flex items-center gap-2 divide-x divide-gray-200 dark:divide-gray-700/40">
      <div :for={i <- 1..3} class="flex flex-col grow p-6">
        <span class="text-sm font-medium text-gray-600 dark:text-gray-300">Value {i}</span>
        <div class="flex gap-2 items-center justify-between">
          <span class="text-xl xl:text-2xl font-semibold text-gray-900 dark:text-white">
            9.6K
          </span>
          <span class="text-xs font-bold flex gap-1 items-center text-success-600 dark:text-success-400">
            <.icon name="remix-arrow-up-fill" class="w-4 h-4" /><span>60.1%</span>
          </span>
        </div>
      </div>
    </.box>
    """
  end

  attr :index, :integer, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block
  slot :switch

  def rule_card(assigns) do
    ~H"""
    <section {@rest} class={["pc-rule-card group", @class]}>
      <div class="flex items-stretch divide-x divide-gray-200 dark:divide-gray-700/40">
        <div class="flex flex-col items-center justify-center drag-handle cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700/50 active:bg-gray-100 dark:active:bg-gray-600">
          <.icon name="custom-drag" class="w-[18px] h-[18px] text-gray-900 dark:text-white" />
        </div>
        <div class="grow flex flex-col divide-y divide-gray-200 dark:divide-gray-700/40">
          <div class="p-3 flex justify-between items-center">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 p-2.5 bg-white dark:bg-gray-800 text-gray-900 dark:text-white rounded-full shadow-0 outline outline-1 outline-offset-[-1px] outline-gray-300 dark:outline-gray-600 inline-flex flex-col justify-center items-center gap-2.5">
                <div class=" text-sm font-semibold leading-tight">
                  {@index}
                </div>
              </div>
              <h4 class="text-sm font-semibold text-gray-900 dark:text-white leading-tight">
                {gettext("Rule priority %{index}", index: @index)}
              </h4>
            </div>
            {render_slot(@switch)}
          </div>
          <div class="p-3 flex justify-between items-center">
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :title, :string, required: true, doc: "labels your dropdown option"
  attr :subtitle, :string, default: nil, doc: "labels your dropdown option"
  attr :values, :list, default: [], doc: "labels your dropdown option"

  def uptime_chart(assigns) do
    assigns =
      assign(assigns, :legend, [
        %{color: "bg-streetlight-100", label: gettext("Allow")},
        %{color: "bg-streetlight-200", label: gettext("Timeout")},
        %{color: "bg-streetlight-300", label: gettext("Block")}
      ])

    ~H"""
    <.box class={[
      @class
    ]}>
      <div class={[
        "px-6 py-4 flex items-center justify-between",
        "border-b border-gray-200 dark:border-gray-700"
      ]}>
        <div class="flex items-center gap-4">
          <.icon
            name="remix-checkbox-circle-fill"
            class={["w-6 h-6", "text-success-500 dark:text-success-400"]}
          />
          <h3 class={["text-base font-semibold", "text-gray-900 dark:text-white"]}>
            {@title}
          </h3>
        </div>
        <div :if={@subtitle} class="text-gray-500 dark:text-gray-400 font-medium">
          {@subtitle}
        </div>
      </div>

      <div class={[
        "p-6 gap-6 flex flex-col"
      ]}>
        <div class="flex justify-between gap-1">
          <div
            :for={item <- @values}
            class={[
              "flex flex-col w-full min-h-20 overflow-hidden",
              "hover:opacity-40 active:opacity-30 focus:opacity-30 cursor-pointer"
            ]}
            id={"uptime-event-#{:rand.uniform(10_000_000) + 1}"}
            phx-hook="TippyHook"
            data-tippy-arrow="false"
            data-tippy-placement="top"
            data-template-selector="div.tippy-template"
          >
            <div
              :for={{color, ratio} <- item}
              class={[
                "rounded",
                "relative bg-gradient-to-b",
                "from-streetlight-#{color + 20}",
                "to-streetlight-#{color + 10}"
              ]}
              style={"height: #{trunc(Float.round(ratio * 100, 0))}%;"}
            >
            </div>

            <div class="hidden tippy-template shadow-4 rounded-lg">
              <div class="flex flex-col px-4 py-2 gap-3">
                <div class="flex flex-col">
                  <p class="text-gray-600 dark:text-gray-300 text-xs">
                    25 May 2024
                  </p>
                  <p class="text-gray-900 dark:text-white text-sm font-semibold leading-tight">
                    No events captured
                  </p>
                </div>

                <div class="flex flex-col gap-1">
                  <div class="flex items-center gap-1">
                    <.icon
                      name="remix-close-circle-fill"
                      class={["w-4 h-4", "text-danger-500 dark:text-danger-400"]}
                    />
                    <h3 class={[
                      "text-xs",
                      "text-gray-900 dark:text-white"
                    ]}>
                      {gettext("https://example.com/mustard")}
                    </h3>
                  </div>
                  <div class="flex items-center gap-1">
                    <.icon
                      name="remix-close-circle-fill"
                      class={["w-4 h-4", "text-warning-500 dark:text-warning-400"]}
                    />
                    <h3 class={[
                      "text-xs",
                      "text-gray-900 dark:text-white"
                    ]}>
                      {gettext("https://example.com/mustard")}
                    </h3>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="flex gap-6 items-center">
          <div :for={item <- @legend} class="flex gap-2 items-center">
            <div class={["w-4 h-2 rounded-full", item.color]}></div>
            <p class="text-gray-600 dark:text-gray-300 text-xs font-semibold">{item.label}</p>
          </div>
        </div>
      </div>
    </.box>
    """
  end

  # Private

  defp generate_qrcode(uri, opts \\ []) do
    uri
    |> EQRCode.encode()
    |> EQRCode.svg(width: Keyword.get(opts, :width, 175))
    |> Phoenix.HTML.raw()
  end

  defp format_secret(secret) do
    secret
    |> Base.encode32(padding: false)
    |> String.graphemes()
    |> Enum.map(&maybe_highlight_digit/1)
    |> Enum.chunk_every(4)
    |> Enum.intersperse(" ")
    |> Phoenix.HTML.raw()
  end

  defp maybe_highlight_digit(char) do
    case Integer.parse(char) do
      :error -> char
      _ -> ~s(<span class="text-primary-600 dark:text-primary-400">#{char}</span>)
    end
  end
end
