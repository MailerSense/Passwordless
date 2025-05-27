defmodule Util.DomainBlocklist do
  @moduledoc """
  Blocklist of domain according to https://github.com/hagezi/dns-blocklists?tab=readme-ov-file#pro
  """

  @domains :passwordless
           |> :code.priv_dir()
           |> Path.join("blocklist/domains.txt")
           |> File.stream!()
           |> Stream.map(&String.trim/1)
           |> Stream.map(&String.downcase/1)
           |> Stream.reject(&String.starts_with?(&1, "#"))
           |> MapSet.new()

  @doc """
  Check if a domain is on the blocklist.
  """
  def blocked?(domain) when is_binary(domain) do
    MapSet.member?(@domains, domain |> String.trim() |> String.downcase())
  end
end
