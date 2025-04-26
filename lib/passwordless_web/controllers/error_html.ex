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
    <.container class="flex flex-col items-center py-6 md:py-16" max_width="sm">
      <.box card>
        <.h3 no_margin class="text-center">
          {"#{@status} #{@message}"}
        </.h3>
        <.p>
          {gettext("Something went wrong: %{reason}", reason: @reason.message)}
        </.p>
        <div class="flex">
          <.button link_type="a" title={gettext("Go to Homepage")} to={~p"/"} class="flex flex-1" />
        </div>
      </.box>
    </.container>
    """
  end

  def render(template, %{status: status, message: message} = assigns) when is_integer(status) and is_binary(message) do
    assigns = Map.put(assigns, :message, Phoenix.Controller.status_message_from_template(template))

    ~H"""
    <.container class="flex flex-col items-center py-6 md:py-16" max_width="sm">
      <.box card>
        <.h3 no_margin class="text-center">
          {@status}
        </.h3>
        <.p>
          {gettext("Something went wrong on our side. Please try again in a moment.")}
        </.p>
        <div class="flex">
          <.button link_type="a" title={gettext("Go to Homepage")} to={~p"/"} class="flex flex-1" />
        </div>
      </.box>
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
    <.container class="flex flex-col items-center py-6 md:py-16" max_width="sm">
      <.box card>
        <.h3 no_margin class="text-center">
          <span :if={@status} class={status_color(@status)}>{@status}</span> {@message}
        </.h3>
        <.p>
          {gettext("Route %{path} not found.", path: @path)}
        </.p>
        <div class="flex">
          <.button link_type="a" title={gettext("Go to Homepage")} to={~p"/"} class="flex flex-1" />
        </div>
      </.box>
    </.container>
    """
  end

  # Private

  defp status_color(404), do: "text-primary-500"
  defp status_color(status) when status in 400..499, do: "text-orange-500"
  defp status_color(status) when status >= 500, do: "text-red-500"
  defp status_color(_status), do: "text-slate-600 dark:text-slate-300"
end
