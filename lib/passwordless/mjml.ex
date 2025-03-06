defmodule Passwordless.MJML do
  @moduledoc false

  def format(mjml) do
    Passwordless.Native.mjml_to_html(mjml, %Passwordless.MJML.RenderOptions{})
  end

  def format!(mjml) do
    {:ok, html} = format(mjml)
    html
  end
end
