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
  def render(template, %{status: status, message: message} = assigns) when is_integer(status) and is_binary(message) do
    assigns = Map.put(assigns, :status_message, Phoenix.Controller.status_message_from_template(template))

    ~H"""
    <.auth_layout title={gettext("%{status}: %{message}", status: @status, message: @status_message)}>
      <:logo>
        <.logo_icon class="w-20 h-20" />
      </:logo>

      <:top_links>
        What's next?
        <.link class="text-blue-600 underline dark:text-blue-400" navigate={~p"/"}>
          {gettext("Back to Home")}
        </.link>
      </:top_links>

      <.form_header title={gettext("Error details")} class="mb-6" />
      <.p class="mb-6">
        {@message}
      </.p>
      <div class="flex">
        <.button link_type="a" title={gettext("Back to Home")} to={~p"/"} class="flex flex-1" />
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
    <.auth_layout title={gettext("%{status}: %{message}", status: @status, message: @message)}>
      <:logo>
        <.logo_icon class="w-20 h-20" />
      </:logo>

      <:top_links>
        What's next?
        <.link class="text-blue-600 underline dark:text-blue-400" navigate={~p"/"}>
          {gettext("Back to Home")}
        </.link>
      </:top_links>

      <.form_header title={gettext("Error details")} class="mb-6" />
      <.p class="mb-6">
        {@reason_message}
      </.p>
      <div class="flex">
        <.button link_type="a" title={gettext("Back to Home")} to={~p"/"} class="flex flex-1" />
      </div>
    </.auth_layout>
    """
  end

  # Private

  defp reason_message(%mod{} = reason) do
    if Kernel.function_exported?(mod, :message, 1) do
      apply(mod, :message, [reason])
    else
      inspect(reason)
    end
  end

  defp reason_message(_reason), do: ""
end
