defmodule IPStack do
  @moduledoc """
  Defines IPStack API client
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.ipstack.com"
  plug Tesla.Middleware.JSON

  @doc """
  Attempts to geolocate the IP address
  """
  def locate(ip_address) do
    with {:ok, %Tesla.Env{body: body}} <- get(authenticate(ip_address)) do
      {:ok, body}
    end
  end

  # Private

  @fields ~w(
    city
    country_code
  )

  defp authenticate(route) do
    params = %{"access_key" => access_token(), "fields" => Enum.join(@fields, ",")}
    route <> "?" <> Plug.Conn.Query.encode(params)
  end

  defp access_token do
    System.get_env("IPSTACK_ACCESS_TOKEN")
  end
end
