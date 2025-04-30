defmodule PasswordlessWeb.ErrorHTML do
  use PasswordlessWeb, :html

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
  def render(template, %{status: status, message: message} = assigns) when is_integer(status) and is_binary(message) do
    assigns = Map.put(assigns, :status_message, Phoenix.Controller.status_message_from_template(template))

    ~H"""
    <.auth_layout title={"#{@status} - #{@message}"}>
      <:logo>
        <.logo_icon class="w-16 h-16" />
      </:logo>

      <:top_links>
        Found a bug?
        <button
          class="text-blue-600 dark:text-blue-400"
          x-data="sentryCrashPopup"
          x-on:click="toggleShow"
        >
          {gettext("Report it")}
        </button>
      </:top_links>

      <.alert color={status_color(@status)} with_icon class="mb-6">
        {@message}
      </.alert>
      <.p class="mb-6">
        {gettext(
          "We're sorry, the page you've requested cannot be shown. Please go back to the homepage, or report the bug above."
        )}
      </.p>
      <div class="flex">
        <.button size="xl" link_type="a" title={gettext("Go Home")} to={~p"/"} class="flex flex-1" />
      </div>
    </.auth_layout>
    """
  end

  def render(template, assigns) do
    assigns =
      assigns
      |> Map.put(:status, get_in(assigns, [:conn, Access.key(:status)]) || 500)
      |> Map.put(:message, Phoenix.Controller.status_message_from_template(template))
      |> Map.put(:reason_message, reason_message(assigns[:reason]))

    ~H"""
    <.auth_layout title={"#{@status} - #{@message}"}>
      <:logo>
        <.logo_icon class="w-16 h-16" />
      </:logo>

      <:top_links>
        Found a bug?
        <button
          class="text-blue-600 dark:text-blue-400"
          x-data="sentryCrashPopup"
          x-on:click="toggleShow"
        >
          {gettext("Report it")}
        </button>
      </:top_links>

      <.alert
        :if={Util.present?(@reason_message)}
        color={status_color(@status)}
        with_icon
        class="mb-6 break-all"
      >
        {@reason_message}
      </.alert>
      <.p class="mb-6">
        {gettext(
          "We're sorry, the page you've requested cannot be shown. Please go back to the homepage, or report the bug above."
        )}
      </.p>
      <div class="flex">
        <.button size="xl" link_type="a" title={gettext("Go Home")} to={~p"/"} class="flex flex-1" />
      </div>
    </.auth_layout>
    """
  end

  # Private

  defp reason_message(%mod{} = _reason) do
    inspect(mod)
  end

  defp reason_message(_reason), do: nil

  defp status_color(status) when is_integer(status) do
    cond do
      status < 400 -> "info"
      status in 400..499 -> "warning"
      true -> "danger"
    end
  end

  defp status_color(_), do: "info"
end
