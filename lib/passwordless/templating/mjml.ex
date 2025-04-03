defmodule Passwordless.Templating.MJML do
  @moduledoc """
  Renders MJML as HTML. Uses the `mjml` library to convert MJML to HTML.
  """

  def convert(mjml) do
    Passwordless.Native.mjml_to_html(mjml, %Passwordless.Templating.MJMLRenderOptions{})
  end

  def convert!(mjml) do
    {:ok, html} = convert(mjml)
    html
  end
end
