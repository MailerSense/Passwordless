defmodule PasswordlessWeb.ErrorHTML do
  use PasswordlessWeb, :html

  import PasswordlessWeb.Components.Typography

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/passwordless_web/controllers/error/404.html.heex
  #   * lib/passwordless_web/controllers/error/500.html.heex
  #
  # embed_templates "error/*"

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def render(template, %{reason: %Phoenix.Router.NoRouteError{plug_status: plug_status}} = assigns)
      when is_integer(plug_status) do
    assigns = Map.put(assigns, :message, Phoenix.Controller.status_message_from_template(template))

    ~H"""
    <.container class="flex flex-col items-center lg:max-w-4xl py-6 md:py-16">
      <.promo_banner
        to={~p"/"}
        icon="remix-alert-fill"
        icon_class="h-4 w-4"
        color_primary="bg-danger-300"
        color_secondary="bg-danger-100"
        class="mb-6"
        content={gettext("Something went wrong")}
      />
      <h1 class="text-white font-display font-bold text-4xl md:text-6xl leading-[44px] md:leading-[74px] tracking-tight text-center mb-6">
        {@status} {@message}
      </h1>
      <p class="inline-block text-white text-center text-lg lg:max-w-2xl mb-6 sm:mb-10">
        {@reason.message}
      </p>
      <div class="flex flex-col sm:flex-row gap-4 items-center">
        <.button size="lg" title={gettext("Go to Homepage")} to={~p"/"} link_type="a" />
        <div class="hidden sm:block">
          <.button
            size="lg"
            title={gettext("Book a Demo")}
            variant="outline"
            with_icon
            to={~p"/book-demo"}
            link_type="a"
          >
            {gettext("Book a Demo")}<.icon name="remix-arrow-right-line" class="w-6 h-6 " />
          </.button>
        </div>
      </div>
    </.container>
    """
  end

  def render(template, %{status: status, message: message} = assigns) when is_integer(status) and is_binary(message) do
    assigns = Map.put(assigns, :message, Phoenix.Controller.status_message_from_template(template))

    ~H"""
    <.container class="flex flex-col items-center lg:max-w-4xl py-6 md:py-16">
      <.promo_banner
        to={~p"/"}
        icon="remix-alert-fill"
        icon_class="h-4 w-4"
        color_primary="bg-danger-300"
        color_secondary="bg-danger-100"
        class="mb-6"
        content={gettext("Something went wrong")}
      />
      <h1 class="text-white font-display font-bold text-4xl md:text-6xl leading-[44px] md:leading-[74px] tracking-tight text-center mb-6">
        {@status}
      </h1>
      <p class="inline-block text-white text-center text-lg lg:max-w-2xl mb-6 sm:mb-10">
        {gettext("Something went wrong on our side. Please try again in a moment.")}
      </p>
      <div class="flex flex-col sm:flex-row gap-4 items-center">
        <.button size="lg" title={gettext("Go to Homepage")} to={~p"/"} link_type="a" />
        <div class="hidden sm:block">
          <.button
            size="lg"
            title={gettext("Book a Demo")}
            variant="outline"
            with_icon
            to={~p"/book-demo"}
            link_type="a"
          >
            {gettext("Book a Demo")}<.icon name="remix-arrow-right-line" class="w-6 h-6 " />
          </.button>
        </div>
      </div>
    </.container>
    """
  end

  def render(template, assigns) do
    assigns =
      assigns
      |> Map.put(:path, get_in(assigns, [:conn, Access.key(:request_path)]) || "")
      |> Map.put(:status, get_in(assigns, [:conn, Access.key(:status)]) || 500)
      |> Map.put(:message, Phoenix.Controller.status_message_from_template(template))

    ~H"""
    <.container class="flex flex-col items-center lg:max-w-4xl py-6 md:py-16">
      <.h1 no_margin class="text-center">
        <span :if={@status} class={status_color(@status)}>{@status}</span> {@message}
      </.h1>
      <.p class="text-sm text-slate-600 dark:text-slate-300 leading-tight text-center">
        {gettext("Route %{path} not found.", path: @path)}
      </.p>
      <.start_for_free_button to={~p"/"} label={gettext("Go to Homepage")} class="flex lg:hidden" />
    </.container>
    """
  end

  # Private

  defp status_color(404), do: "text-primary-500"
  defp status_color(status) when status in 400..499, do: "text-orange-500"
  defp status_color(status) when status >= 500, do: "text-red-500"
  defp status_color(_status), do: "text-slate-600 dark:text-slate-300"
end
