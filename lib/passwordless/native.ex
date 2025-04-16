defmodule Passwordless.Native do
  @moduledoc """
  Native bindings.
  """

  use Rustler,
    crate: "passwordless_native",
    otp_app: :passwordless,
    skip_compilation?: Mix.env() in [:prod, :test]

  alias Passwordless.Templating.MJMLRenderOptions

  @doc """
  Converts MJML to HTML.
  """
  @spec mjml_to_html(binary(), MJMLRenderOptions.t()) :: {:ok, binary()} | {:error, any()}
  def mjml_to_html(_mjml, _render_options), do: :erlang.nif_error(:nif_not_loaded)

  @type language :: :javascript | :typescript | :html

  @doc """
  Formats programming code.
  """
  @spec format_code(binary(), language()) :: binary()
  def format_code(_code, _language), do: :erlang.nif_error(:nif_not_loaded)
end
