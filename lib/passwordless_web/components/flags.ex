defmodule PasswordlessWeb.Components.Flags do
  @moduledoc "Flag SVGs embedded at compile time."

  @flags_dir Path.join(:code.priv_dir(:passwordless), "flags")

  @flag_svgs for file <- File.ls!(@flags_dir),
                 extname = Path.extname(file),
                 extname == ".svg",
                 name = Path.rootname(file),
                 do: {name, File.read!(Path.join(@flags_dir, file))}

  @flags Map.new(@flag_svgs)

  @doc """
  Return raw SVG markup for a given flag code, e.g. `us` or `de`"
  This can be used in a `raw` function to render the SVG directly.
  """
  def get(code) when is_binary(code), do: Map.get(@flags, code)

  @doc """
  Return a data URL for a given flag code, e.g. `us` or `de`
  This can be used in an `img` tag or as a background image.
  """
  def data_url(code) do
    with svg when is_binary(svg) <- get(code) do
      "data:image/svg+xml;base64,#{Base.encode64(svg)}"
    end
  end
end
