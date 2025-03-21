defmodule PasswordlessWeb.Components.ThemeSwitch do
  @moduledoc false
  use Phoenix.Component

  import PasswordlessWeb.Components.Icon

  attr :class, :string, default: ""

  @doc """
  A button that switches between light and dark modes.

  ## Examples
      <.theme_switch />
  """
  def theme_switch(assigns) do
    assigns = assign_new(assigns, :id, fn -> Util.id("theme_switch") end)

    ~H"""
    <button
      id={@id}
      type="button"
      class={["color-scheme", "pc-theme-switcher--button", @class]}
      phx-hook="ColorSchemeHook"
      aria-label="Change color scheme"
    >
      <.icon name="remix-moon-fill" class="hidden w-5 h-5 color-scheme-dark-icon" />
      <.icon name="remix-sun-fill" class="hidden w-5 h-5 color-scheme-light-icon" />
    </button>
    """
  end

  attr :class, :string, default: ""

  def wide_theme_switch(assigns) do
    assigns = assign_new(assigns, :id, fn -> Util.id("theme_switch") end)

    ~H"""
    <button
      phx-hook="ColorSchemeHook"
      type="button"
      aria-label="Change color scheme"
      id={Ecto.UUID.generate()}
      class={[
        "h-12 px-1.5 bg-slate-800 rounded-full border border-slate-700 flex items-center w-full",
        @class
      ]}
    >
      <div class="grow shrink basis-0 h-9 p-2 bg-slate-900 dark:bg-transparent text-white dark:text-slate-400 rounded-full justify-center items-center gap-2 flex select-none">
        <.icon name="remix-sun-fill" class="w-[18px] h-[18px]" />
        <p class="text-sm font-semibold leading-tight">Light</p>
      </div>
      <div class="grow shrink basis-0 h-9 p-2 bg-transparent dark:bg-slate-900 text-slate-400 dark:text-white rounded-full justify-center items-center gap-2 flex select-none">
        <.icon name="remix-moon-fill" class="w-[18px] h-[18px]" />
        <p class="text-sm font-semibold leading-tight">Dark</p>
      </div>
    </button>
    """
  end
end
