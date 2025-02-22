defmodule PasswordlessWeb.Plugs.ParseIP do
  @moduledoc """
  Get public IP address of user from the x-forwarded-for header
  """

  import Plug.Conn

  @header "x-forwarded-for"

  def parse_ip(%Plug.Conn{assigns: %{current_user_ip: _}} = conn, _opts), do: conn

  def parse_ip(%Plug.Conn{} = conn, _opts) do
    process(conn, List.first(get_req_header(conn, @header)))
  end

  # Private

  defp process(%Plug.Conn{} = conn, forwarded_ip) when is_binary(forwarded_ip) do
    with {:ok, ip_address} <- InetCidr.parse_address(forwarded_ip), true <- is_public_ip(ip_address) do
      assign(%Plug.Conn{conn | remote_ip: ip_address}, :current_user_ip, format_ip(ip_address))
    else
      _ -> assign(conn, :current_user_ip, format_ip(conn.remote_ip))
    end
  end

  defp process(%Plug.Conn{} = conn, _remote_ip) do
    assign(conn, :ip, format_ip(conn.remote_ip))
  end

  defp format_ip(ip), do: to_string(:inet.ntoa(ip))

  defp is_public_ip({_, _, _, _} = ip_address) do
    case ip_address do
      {10, _, _, _} -> false
      {192, 168, _, _} -> false
      {172, second, _, _} when second >= 16 and second <= 31 -> false
      {127, 0, 0, _} -> false
      {_, _, _, _} -> true
      :einval -> false
    end
  end

  defp is_public_ip(_ip_address), do: true
end
