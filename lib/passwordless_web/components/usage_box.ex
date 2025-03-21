defmodule PasswordlessWeb.Components.UsageBox do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Components.Progress

  attr :class, :string, default: ""
  attr :plan, :string, default: "Free"
  attr :usage, :integer, default: 0
  attr :usage_max, :integer, default: 1000

  def usage_box(assigns) do
    ~H"""
    <.a
      to={~p"/app/billing"}
      link_type="live_redirect"
      class="relative p-3 rounded-xl border border-slate-700 flex-col gap-3 flex overflow-hidden"
    >
      <div class="absolute w-60 h-60 bg-primary-700/20 rounded-full blur-[50px] -top-36 -left-1/2">
      </div>
      <div class="absolute w-[180px] h-[180px] bg-primary-700/20 rounded-full blur-[100px] left-1/2 top-24">
      </div>
      <div class="text-slate-500 text-xs font-semibold uppercase">
        {gettext("Plan")}
      </div>
      <div class="items-center gap-1 inline-flex">
        <div class="text-white text-sm font-medium leading-tight">{gettext("Passwordless")}</div>
        <div class="px-2 py-0.5 bg-[#2e90fa]/20 rounded-[100px] border border-[#53b0fd]/20 justify-center items-center gap-2.5 flex">
          <div class="text-white text-sm font-medium leading-tight">{@plan}</div>
        </div>
      </div>
      <.progress color="primary-dark" value={@usage} max={@usage_max} size="sm" class="max-w-full" />
      <div class="flex gap-1 items-center">
        <span class="text-white text-xs font-normal">
          {Passwordless.Locale.Number.to_string!(@usage)}
        </span>
        <span class="text-slate-400 text-xs font-normal">
          / {Passwordless.Locale.Number.to_string!(@usage_max)} {gettext("contacts")}
        </span>
      </div>
      <span class="text-slate-400 text-xs font-medium underline">
        {gettext("Upgrade account")}
      </span>
    </.a>
    """
  end
end
