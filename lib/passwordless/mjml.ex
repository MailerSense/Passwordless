defmodule Passwordless.MJML do
  @moduledoc false

  def convert(mjml) do
    Passwordless.Native.mjml_to_html(mjml, %Passwordless.MJML.RenderOptions{})
  end

  def convert!(mjml) do
    {:ok, html} = convert(mjml)
    html
  end
end
