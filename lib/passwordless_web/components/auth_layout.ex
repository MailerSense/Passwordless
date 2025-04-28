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
    <section class="fixed w-full h-full overflow-y-scroll bg-slate-100 dark:bg-slate-900" {@rest}>
      <div class="flex flex-col justify-center py-12 sm:px-6 lg:px-8">
        <div class="text-center sm:mx-auto sm:w-full sm:max-w-md">
          <div class="flex justify-center mb-10">
            <.link href="/">
              {render_slot(@logo)}
            </.link>
          </div>

          <.h2>
            {@title}
          </.h2>

          <%= if render_slot(@top_links) do %>
            <.p>
              {render_slot(@top_links)}
            </.p>
          <% end %>
        </div>
      </div>

      <div class="pb-20 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="px-8 py-8 bg-white shadow-1 sm:rounded-lg sm:px-10 dark:bg-slate-800">
          {render_slot(@inner_block)}
        </div>

        <%= if render_slot(@bottom_links) do %>
          <div class="mt-5 text-center">
            {render_slot(@bottom_links)}
          </div>
        <% end %>
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
      <h2 class="text-slate-900 text-center text-2xl font-semibold">
        {@title}
      </h2>
    </div>
    """
  end
end
