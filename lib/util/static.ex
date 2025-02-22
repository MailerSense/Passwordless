defmodule Util.Static do
  @moduledoc false

  @doc """
  Parses an AWS IAM JSON policy.
  """
  if Mix.env() == :prod do
    @cdn_base_url "https://cdn.livecheck.io/static-assets"

    def sigil_STATIC(path, []), do: @cdn_base_url <> path
  else
    def sigil_STATIC(path, []), do: path
  end
end
