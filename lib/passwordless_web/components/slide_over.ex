defmodule PasswordlessWeb.Components.SlideOver do
  @moduledoc false
  use Phoenix.Component

  alias PasswordlessWeb.Components.Icon
  alias Phoenix.LiveView.JS

  attr(:origin, :string,
    default: "right",
    values: ["left", "right", "top", "bottom"],
    doc: "slideover point of origin"
  )

  attr(:close_slide_over_target, :string,
    default: nil,
    doc:
      "close_slide_over_target allows you to target a specific live component for the close event to go to. eg: close_slide_over_target={@myself}"
  )

  attr(:close_on_click_away, :boolean,
    default: true,
    doc: "whether the slideover should close when a user clicks away"
  )

  attr(:close_on_escape, :boolean,
    default: true,
    doc: "whether the slideover should close when a user hits escape"
  )

  attr(:title, :string, default: nil, doc: "slideover title")

  attr(:max_width, :string,
    default: "sm",
    values: ["sm", "md", "lg", "xl", "2xl", "full"],
    doc: "sets container max-width"
  )

  attr(:header, :boolean, default: true, doc: "whether to show header")
  attr(:class, :string, default: "", doc: "CSS class")
  attr(:hide, :boolean, default: false, doc: "slideover is hidden")
  attr(:rest, :global)
  slot(:actions, required: false)
  slot(:inner_block, required: false)

  def slide_over(assigns) do
    ~H"""
    <div
      {@rest}
      id="slide-over"
      class="hidden pc-slide-over"
      phx-mounted={!@hide && show_slide_over(@origin)}
      phx-remove={hide_slide_over(@origin, @close_slide_over_target)}
    >
      <div id="slide-over-overlay" class="pc-slideover__overlay" aria-hidden="true"></div>

      <div
        class={["pc-slideover__wrapper", get_margin_classes(@origin), @class]}
        role="dialog"
        aria-label="slide-over-content-wrapper"
        aria-modal="true"
      >
        <div
          id="slide-over-content"
          class={get_classes(@max_width, @origin, @class)}
          phx-click-away={@close_on_click_away && hide_slide_over(@origin, @close_slide_over_target)}
          phx-window-keydown={@close_on_escape && hide_slide_over(@origin, @close_slide_over_target)}
          phx-key="escape"
        >
          <div class="pc-slideover__container">
            <div :if={@header} class="pc-slideover__header">
              <div class="pc-slideover__header__container">
                <h2 class="pc-slideover__header__text">
                  {@title}
                </h2>

                <button
                  type="button"
                  title="Close"
                  aria-label="Close"
                  phx-click={hide_slide_over(@origin, @close_slide_over_target)}
                  class="pc-slideover__header__button"
                >
                  <div class="sr-only">Close</div>
                  <Icon.icon name="remix-close-line" class="w-8 h-8 text-slate-900 dark:text-white" />
                </button>
              </div>
            </div>

            <div class="pc-slideover__content">
              {render_slot(@inner_block)}
            </div>

            <div :if={Util.present?(@actions)} class="pc-slideover__actions">
              {render_slot(@actions)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_slide_over(origin) do
    {start_class, end_class} = get_transition_classes(origin)

    %JS{}
    |> JS.show(to: "#slide-over")
    |> JS.show(
      to: "#slide-over-overlay",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#slide-over-content",
      transition: {
        "transition-all transform ease-out duration-300",
        start_class,
        end_class
      }
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "#slide-over-content")
  end

  # The live view that calls <.slide_over> will need to handle the "close_slide_over" event. eg:
  # def handle_event("close_slide_over", _, socket) do
  #   {:noreply, push_patch(socket, to: Routes.moderate_users_path(socket, :index))}
  # end
  def hide_slide_over(origin, close_slide_over_target \\ nil) do
    {end_class, start_class} = get_transition_classes(origin)

    js =
      "overflow-hidden"
      |> JS.remove_class(to: "body")
      |> JS.hide(
        transition: {
          "ease-in duration-200",
          "opacity-100",
          "opacity-0"
        },
        to: "#slide-over-overlay"
      )
      |> JS.hide(
        transition: {
          "ease-in duration-200",
          start_class,
          end_class
        },
        to: "#slide-over-content"
      )
      |> JS.hide(to: "#slide-over")

    if close_slide_over_target do
      JS.push(js, "close_slide_over", target: close_slide_over_target)
    else
      JS.push(js, "close_slide_over")
    end
  end

  # Private

  defp get_transition_classes(origin) do
    case origin do
      "left" -> {"-translate-x-full", "translate-x-0"}
      "right" -> {"translate-x-full", "-translate-x-0"}
      "top" -> {"-translate-y-full", "translate-y-0"}
      "bottom" -> {"translate-y-full", "translate-y-0"}
      _ -> {"", ""}
    end
  end

  defp get_classes(max_width, origin, class) do
    base_classes = "pc-slideover__box"

    slide_over_classes =
      case origin do
        "left" -> "fixed left-0 inset-y-0 transform -translate-x-full"
        # transform translate-x-full
        "right" -> "fixed right-0 inset-y-0"
        "top" -> "fixed inset-x-0 top-0 transform -translate-y-full"
        "bottom" -> "fixed inset-x-0 bottom-0 transform translate-y-full"
      end

    max_width_class =
      case origin do
        x when x in ["left", "right"] ->
          "pc-slideover__box--#{max_width}"

        x when x in ["top", "bottom"] ->
          ""
      end

    custom_classes = class

    [slide_over_classes, max_width_class, base_classes, custom_classes]
  end

  defp get_margin_classes(margin) do
    case margin do
      "left" -> "mr-10"
      "right" -> "ml-10"
      "top" -> "mb-10"
      "bottom" -> "mt-10"
    end
  end
end
