defmodule PasswordlessWeb.Components.UsageBox do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Components.Progress

  alias Passwordless.Locale.Number, as: NumberLocale

  attr :class, :string, default: ""
  attr :trial_days, :integer, required: true

  def trial_warning_box(assigns) do
    ~H"""
    <div class="rounded-xl flex flex-col bg-slate-950 p-3">
      <span class="text-warning-500 text-xs font-semibold uppercase leading-tight mb-3">
        {gettext("Trial")}
      </span>
      <span class="text-white text-sm font-medium leading-tight">
        You are currently on the Business Plan Trial. You still have {ngettext(
          "1 day",
          "%{count} days",
          @trial_days
        )} left.
      </span>
    </div>
    """
  end

  attr :class, :string, default: ""
  attr :plan, :string, default: "Free"
  attr :limits, :list, default: []

  def usage_box(assigns) do
    ~H"""
    <.a to={~p"/app/billing"} link_type="live_redirect">
      <article class="rounded-xl flex-col bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-400 shadow-0">
        <div class="gap-3 flex flex-col p-3">
          <span class="text-xs font-semibold uppercase leading-tight  text-slate-500 dark:text-slate-500">
            {gettext("Usage")}
          </span>

          <%= for %{current: current, unit: unit, max: max} <- @limits do %>
            <div class="flex flex-col gap-1">
              <.progress color="primary" value={current} max={max} size="sm" />
              <span class="text-sm">
                <span class="text-slate-900 dark:text-white">{NumberLocale.to_string!(current)}</span>
                / {NumberLocale.to_string!(max)} {unit}
              </span>
            </div>
          <% end %>

          <span class="text-xs font-medium underline">
            {gettext("Upgrade plan")}
          </span>
        </div>
      </article>
    </.a>
    """
  end
end
