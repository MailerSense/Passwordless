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
    assigns = assign_new(assigns, :id, fn -> "theme_switch_#{:rand.uniform(10_000_000) + 1}" end)

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
    assigns = assign_new(assigns, :id, fn -> "theme_switch_#{:rand.uniform(10_000_000) + 1}" end)

    ~H"""
    <button
      phx-hook="ColorSchemeHook"
      type="button"
      aria-label="Change color scheme"
      id={@id}
      class={[
        "p-1 px-1.5 flex rounded-full items-center justify-center bg-slate-200 dark:bg-slate-900",
        @class
      ]}
    >
      <div class={[
        "flex items-center justify-center py-2.5 px-6 text-sm font-semibold leading-tight rounded-full whitespace-nowrap select-none gap-2.5",
        "bg-white text-slate-900 shadow-1 dark:bg-transparent dark:shadow-none dark:text-slate-400",
        "grow"
      ]}>
        <.icon name="remix-sun-fill" class="w-[18px] h-[18px]" />
        <p class="text-sm font-semibold leading-tight">Light</p>
      </div>
      <div class={[
        "flex items-center justify-center py-2.5 px-6 text-sm font-semibold leading-tight rounded-full whitespace-nowrap select-none gap-2.5",
        "dark:bg-slate-700 dark:text-white dark:shadow-1",
        "grow"
      ]}>
        <.icon name="remix-moon-fill" class="w-[18px] h-[18px]" />
        <p class="text-sm font-semibold leading-tight">Dark</p>
      </div>
    </button>
    """
  end
end
