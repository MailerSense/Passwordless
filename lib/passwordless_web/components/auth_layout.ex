defmodule PasswordlessWeb.Components.AuthLayout do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Typography

  attr :title, :string
  attr :rest, :global, doc: "other html attributes"
  slot(:inner_block)
  slot(:logo)
  slot(:top_links)
  slot(:bottom_links)

  def auth_layout(assigns) do
    ~H"""
    <section
      class="fixed w-full h-full overflow-y-scroll bg-slate-100 dark:bg-slate-900 sm:pt-20"
      {@rest}
    >
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="p-6 sm:p-10 bg-white shadow-4 sm:rounded-2xl dark:bg-slate-800/30 sm:border border-transparent dark:border-slate-700/40">
          <div class="flex flex-col items-center mb-6 sm:mb-10">
            <.link href="/" class="flex justify-center mb-8">
              {render_slot(@logo)}
            </.link>

            <.h2>
              {@title}
            </.h2>

            <.p :if={Util.present?(@top_links)}>
              {render_slot(@top_links)}
            </.p>
          </div>

          {render_slot(@inner_block)}
        </div>

        <div :if={Util.present?(@bottom_links)} class="my-8 text-center">
          {render_slot(@bottom_links)}
        </div>
      </div>
    </section>
    """
  end

  attr :title, :string, required: true, doc: "The title of the page"
  attr :subtitle, :string, default: nil, doc: "The subtitle of the page"
  attr :class, :string, default: "", doc: "CSS class"
  attr :rest, :global

  def auth_header(assigns) do
    ~H"""
    <div class={["flex flex-col gap-2 mb-8 items-center", @class]} {@rest}>
      <h4 :if={@subtitle} class="text-center text-slate-500 text-xs font-semibold uppercase">
        {@subtitle}
      </h4>
      <h2 class="text-slate-900 text-center text-2xl md:text-5xl font-semibold">
        {@title}
      </h2>
    </div>
    """
  end
end
