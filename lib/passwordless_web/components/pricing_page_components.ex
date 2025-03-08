defmodule PasswordlessWeb.PricingPageComponents do
  @moduledoc """
  A set of components for use in a pricing page.
  """

  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Button
  import PasswordlessWeb.Components.Container
  import PasswordlessWeb.Components.Icon

  alias PasswordlessWeb.Product

  attr :class, :string, default: "", doc: "CSS class"

  def pricing_plans(assigns) do
    ~H"""
    <div class={["grid gap-5 grid-cols-1 md:grid-cols-2 xl:grid-cols-3", @class]}>
      <.pricing_plan :for={plan <- Product.pricing_plans2()} {plan} />
    </div>
    """
  end

  attr :plans, :list, default: [], doc: "The pricing plan sections"
  attr :sections, :list, default: [], doc: "The pricing plan sections"

  def pricing_plan_table(assigns) do
    ~H"""
    <%= for {section, i} <- Enum.with_index(@sections) do %>
      <%= if i == 0 do %>
        <div class="grid grid-cols-3 border-b-2 border-gray-200">
          <h3 class="text-gray-900 text-lg font-semibold leading-7 py-8 tracking-tight">
            {section.title}
          </h3>
          <h3
            :for={plan <- @plans}
            class="text-gray-900 text-lg font-semibold leading-7 py-8 px-6 bg-primary-50 tracking-tight"
          >
            {plan}
          </h3>
        </div>
      <% else %>
        <div class="py-8 border-b-2 border-gray-200 gap-6 flex mt-5">
          <h3 class="text-gray-900 text-lg font-semibold leading-7 tracking-tight">
            {section.title}
          </h3>
        </div>
      <% end %>

      <div :for={row <- section.rows} class="grid grid-cols-3 border-b border-gray-200">
        <%= for {col, i} <- Enum.with_index(row) do %>
          <%= cond do %>
            <% is_boolean(col) -> %>
              <span class={[
                "h-[60px] flex items-center",
                if(i == 0,
                  do: "",
                  else: "px-6"
                ),
                if(i != Enum.count(row) - 1,
                  do: "border-r border-gray-200",
                  else: ""
                )
              ]}>
                <.icon
                  name={if col, do: "remix-checkbox-circle-fill", else: "remix-close-circle-fill"}
                  class={[
                    "w-6 h-6",
                    if(col, do: "bg-gray-900", else: "bg-gray-300")
                  ]}
                />
              </span>
            <% is_binary(col) -> %>
              <span class={[
                "h-[60px] flex items-center",
                if(i != Enum.count(row) - 1,
                  do: "border-r border-gray-200",
                  else: ""
                )
              ]}>
                <p class={[
                  if(i == 0,
                    do: "text-gray-600 text-sm font-normal",
                    else: "px-6 text-gray-900 text-sm font-medium leading-tight"
                  )
                ]}>
                  {col}
                </p>
              </span>
            <% is_tuple(col) -> %>
              <span class={[
                "h-[60px] flex items-center",
                if(i != Enum.count(row) - 1,
                  do: "border-r border-gray-200",
                  else: ""
                )
              ]}>
                <p
                  id={elem(col, 0)}
                  class={[
                    if(i == 0,
                      do:
                        "text-gray-600 text-sm font-normal underline decoration-dashed cursor-help pr-2",
                      else: "px-6 text-gray-900 text-sm font-medium leading-tight"
                    )
                  ]}
                  style="text-decoration-style: dashed;"
                  phx-hook="TippyHook"
                  data-tippy-content={elem(col, 1)}
                  data-tippy-placement="right"
                >
                  {elem(col, 0)}
                </p>
              </span>
          <% end %>
        <% end %>
      </div>
    <% end %>
    """
  end

  attr :class, :string, default: "", doc: "CSS class"
  attr :options, :list, default: [], doc: "The options for these tabs"
  attr :variable, :string, required: true, doc: "CSS class"

  def pricing_tabs(assigns) do
    ~H"""
    <nav class={[
      "p-1 bg-gray-200 rounded-xl justify-start items-center gap-1 inline-flex",
      @class
    ]}>
      <%= for option <- @options do %>
        <button
          @click={"#{@variable} = '#{option.id}'"}
          class="px-4 py-2 rounded-lg gap-2 flex items-center min-h-[38px] cursor-pointer select-none"
          x-bind:class={"{
            'text-gray-900 bg-white shadow': #{@variable} === '#{option.id}',
            'text-gray-600': #{@variable} !== '#{option.id}'
          }"}
        >
          <p class="text-center text-sm font-semibold leading-tight">
            {option.label}
          </p>
          <%= if option[:modifier] do %>
            <div class={[
              "px-1 py-0.5 bg-gray-900 rounded justify-start gap-2.5 flex"
            ]}>
              <p class="text-primary-300 text-xs font-bold">
                {option.modifier}
              </p>
            </div>
          <% end %>
        </button>
      <% end %>
    </nav>
    """
  end

  attr :plans, :list, default: [], doc: "The pricing plan sections"
  attr :sections, :list, default: [], doc: "The pricing plan sections"
  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]
  attr :expanded, :boolean, default: false, doc: "Whether the pricing details are expanded"
  attr :class, :any, default: nil, doc: "CSS class for parent container"
  attr :rest, :global

  def pricing_details(assigns) do
    ~H"""
    <div
      {@rest}
      x-data={"{ expanded: #{@expanded} }"}
      class={[
        "bg-white border-b border-gray-200 justify-center items-center gap-4 flex flex-col rounded-3xl",
        @class
      ]}
    >
      <div
        class="flex gap-4 items-center justify-center cursor-pointer p-6 w-full select-none"
        @click="expanded = !expanded"
        x-bind:class="{ 'border-b border-gray-200': expanded }"
      >
        <p class="text-gray-900 font-semibold">{gettext("Compare plans")}</p>
        <.icon
          name="remix-arrow-down-s-line"
          class="w-6 h-6 transition duration-150 ease-in-out"
          x-bind:class="{ 'rotate-180': expanded }"
        />
      </div>

      <div x-show="expanded" x-collapse class="w-full py-16">
        <.container max_width={@max_width}>
          <.pricing_plan_table plans={@plans} sections={@sections} />
        </.container>
      </div>
    </div>
    """
  end

  def pricing_js_data(assigns \\ %{}) do
    %{
      "x-data": "{
        chosenPricing: 'yearly',
        chosenCurrency: 'USD',
        chosenChecks: '#{Map.get(assigns, :checks, 5)}',
        initialChosenChecks: '#{Map.get(assigns, :initial_checks, 5)}',
        showUpgradeText: #{Map.get(assigns, :show_upgrade, false)},
        get chosenInterval() {
          let config = {
            5: 'hour',
            15: 'hour',
            25: '30 minutes',
            50: '30 minutes'
          };

          return config[this.chosenChecks];
        },
        get chosenSchedules() {
          let config = {
            5: '5',
            15: '20',
            25: '30',
            50: '60'
          };

          return config[this.chosenChecks];
        },
        get chosenStatusPages() {
          let config = {
            5: '5',
            15: 'unlimited',
            25: 'unlimited',
            50: 'unlimited'
          };

          return config[this.chosenChecks];
        },
        get businessUpgradeText() {
          let config = {
            5: 'Upgrade to 5 Passwordlesss',
            15: 'Upgrade to 15 Passwordlesss',
            25: 'Upgrade to 25 Passwordlesss',
            50: 'Upgrade to 50 Passwordlesss'
          };

          if (this.chosenChecks === this.initialChosenChecks) {
            return 'Currently up to ' + this.chosenChecks + ' checks';
          }

          return config[this.chosenChecks];
        },
        yearlyDiscount: 1 - 0.2,
        usdPlan: [
          [5, 70],
          [15, 449],
          [25, 749],
          [50, 1499],
        ],
        eurPlan: [
          [5, 70],
          [15, 449],
          [25, 749],
          [50, 1499],
        ],
        usdFormat: new Intl.NumberFormat('en-US', {
          style: 'currency',
          currency: 'USD',
        }),
        euroFormat: new Intl.NumberFormat('en-US', {
          style: 'currency',
          currency: 'EUR',
        }),
        pricingTiers(checks, billing, currency) {
          let plan;
          if (currency === 'USD') {
            plan = this.usdPlan;
          } else if (currency === 'EUR') {
            plan = this.eurPlan;
          }

          let monthlyPrice = 0;
          for (const tier of plan) {
            if (checks == tier[0]) {
              monthlyPrice = tier[1];
              break;
            }
          }

          if (billing === 'yearly') {
            monthlyPrice = Math.ceil(monthlyPrice * this.yearlyDiscount);
          }

          return monthlyPrice;
        },
        formatCurrency(value, currency) {
          if (currency === 'USD') {
            return this.usdFormat.format(value).replace(/\.00$/, '');
          } else if (currency === 'EUR') {
            return this.euroFormat.format(value).replace(/\.00$/, '');
          }
        }
      }"
    }
  end

  # Private

  attr :class, :string, default: "", doc: "CSS class"
  attr :options, :list, default: [], doc: "The options for these tabs"
  attr :variable, :string, required: true, doc: "CSS class"

  defp pricing_check_tabs(assigns) do
    ~H"""
    <nav class={[
      "p-1 bg-gray-100 rounded-lg items-center gap-1 flex",
      @class
    ]}>
      <%= for option <- @options do %>
        <button
          @click={"#{@variable} = '#{option.id}'"}
          class="px-3 py-2 rounded-lg gap-2 flex items-center justify-center min-w-[40px] min-h-[34px] cursor-pointer"
          x-bind:class={"{
            'text-primary-300 bg-gray-900': #{@variable} === '#{option.id}',
            'text-gray-500': #{@variable} !== '#{option.id}'
          }"}
        >
          <p class="text-center text-sm font-semibold">
            {option.label}
          </p>
        </button>
      <% end %>
    </nav>
    """
  end

  attr :dark, :boolean, default: true, doc: "Dark mode"
  attr :title, :string, required: true, doc: "The title of this plan"
  attr :description, :string, default: nil, doc: "The description of this plan"
  attr :details, :string, default: "", doc: "The details of this plan"
  attr :action_text, :string, required: true, doc: "The action of this plan"
  attr :action_path, :string, required: true, doc: "The action path of this plan"
  attr :features, :list, default: [], doc: "The features of this plan"
  attr :class, :string, default: "", doc: "CSS class"
  attr :kind, :atom, default: :free, values: [:free, :business, :enterprise], doc: "The kind of this plan"

  defp pricing_plan(assigns) do
    ~H"""
    <article class={[
      "px-6 py-8 rounded-xl flex flex-col gap-8 border relative",
      pricing_plan_class(@kind),
      @class
    ]}>
      <%= case @kind do %>
        <% :enterprise -> %>
          <div class="flex flex-col gap-4">
            <h3 class="text-white text-3xl font-semibold leading-[38px] line-clamp-1 tracking-tight">
              {@title}
            </h3>
            <p :if={@description} class="text-white line-clamp-3">
              {@description}
            </p>
          </div>
        <% _ -> %>
          <div class="flex flex-col gap-4">
            <h3 class="text-gray-900 text-3xl font-semibold leading-[38px] line-clamp-1 tracking-tight">
              {@title}
            </h3>
            <p :if={@description} class="text-gray-600 line-clamp-3">
              {@description}
            </p>
          </div>
      <% end %>

      <%= case @kind do %>
        <% :enterprise -> %>
          <div class="h-[72px]" />
          <.button size="lg" variant="outline" label={@action_text} to={@action_path} link_type="a" />
          <div class="flex flex-col gap-4 border-t border-gray-700 pt-8">
            <.pricing_plan_list kind={:enterprise} features={@features} />
          </div>
        <% _ -> %>
          <div class="flex flex-col gap-2">
            <div class="flex gap-2 items-baseline">
              <p class="text-gray-900 text-6xl font-semibold font-display leading-[72px] tracking-tight">
                <%= if @kind == :business do %>
                  <span x-text="formatCurrency(pricingTiers(chosenChecks, chosenPricing, chosenCurrency), chosenCurrency)">
                  </span>
                <% else %>
                  <span x-text="formatCurrency(0, chosenCurrency)"></span>
                <% end %>
              </p>
              <p class="text-gray-600 text-lg font-medium font-display">
                /{gettext("month")}
              </p>
            </div>
          </div>

          <.button
            size="lg"
            color={if(@kind == :business, do: "secondary", else: "wireframe")}
            label={@action_text}
            to={@action_path}
            link_type="a"
          />

          <div class="flex flex-col gap-4 border-t border-gray-200 pt-8">
            <.pricing_plan_list kind={@kind} features={@features} />
          </div>
      <% end %>
    </article>
    """
  end

  attr :kind, :atom, default: :free, values: [:free, :business, :enterprise], doc: "The kind of this plan"
  attr :features, :list, required: true, doc: "The features of this plan"

  defp pricing_plan_list(assigns) do
    assigns =
      assign(assigns,
        li_class:
          case assigns.kind do
            :free -> "text-gray-900"
            :business -> "text-gray-900"
            :enterprise -> "text-white"
          end,
        icon_class:
          case assigns.kind do
            :free -> "bg-gray-300"
            :business -> "bg-gray-900"
            :enterprise -> "bg-primary-300"
          end
      )

    ~H"""
    <ul class="flex flex-col gap-3">
      <%= for {checked, item} <- @features do %>
        <li class={[
          @li_class,
          "flex gap-2 items-center text-lg leading-tight"
        ]}>
          <.icon
            name={if checked, do: "remix-checkbox-circle-fill", else: "remix-close-circle-fill"}
            class={[
              "w-6 h-6",
              if(checked,
                do: @icon_class,
                else: "bg-gray-300"
              )
            ]}
          />
          {item}
        </li>
      <% end %>
    </ul>
    """
  end

  defp pricing_plan_class(:enterprise), do: "bg-gray-900 border-gray-200"
  defp pricing_plan_class(:business), do: "bg-white border-gray-200 shadow-4"
  defp pricing_plan_class(_), do: "bg-white border-gray-200"
end
