defmodule Passwordless.GeoIP do
  @moduledoc """
  Map public IP addresses to their geographical origin.
  """

  @db :passwordless
      |> :code.priv_dir()
      |> Path.join("geoip/GeoLite2-City.mmdb")
      |> File.read!()
      |> MMDB2Decoder.parse_database()

  def lookup(ip) when is_binary(ip) do
    with {:ok, ip} <- :inet.parse_address(String.to_charlist(ip)), do: MMDB2Decoder.pipe_lookup(@db, ip)
  end
end
