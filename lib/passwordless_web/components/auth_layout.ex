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
      class="fixed w-full h-full overflow-y-scroll bg-slate-100 dark:bg-slate-900 sm:py-16"
      {@rest}
    >
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <div class="px-10 py-10 bg-white shadow-3 sm:rounded-2xl  dark:bg-slate-800">
          <div class="flex flex-col items-center mb-10">
            <div class="flex justify-center mb-8">
              <.link href="/">
                {render_slot(@logo)}
              </.link>
            </div>

            <.h2>
              {@title}
            </.h2>

            <.p :if={Util.present?(@top_links)}>
              {render_slot(@top_links)}
            </.p>
          </div>

          {render_slot(@inner_block)}
        </div>

        <div :if={Util.present?(@bottom_links)} class="mt-8 text-center">
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
