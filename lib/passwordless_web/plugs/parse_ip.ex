defmodule PasswordlessWeb.Plugs.ParseIP do
  @moduledoc """
  Get public IP address of user from the x-forwarded-for header
  """

  import Plug.Conn

  @for_regex ~r/for=(?<for>[^;,]+).*$/

  def parse_ip(%Plug.Conn{assigns: %{current_user_ip: _}} = conn, _opts), do: conn

  def parse_ip(%Plug.Conn{} = conn, _opts) do
    cf_connecting_ip = List.first(get_req_header(conn, "cf-connecting-ip"), "")
    x_forwarded_for = List.first(get_req_header(conn, "x-forwarded-for"), "")
    b_forwarded_for = List.first(get_req_header(conn, "b-forwarded-for"), "")
    forwarded = List.first(get_req_header(conn, "forwarded"), "")

    remote_ip =
      cond do
        byte_size(cf_connecting_ip) > 0 ->
          cf_connecting_ip |> clean_ip() |> ensure_ip()

        byte_size(b_forwarded_for) > 0 ->
          b_forwarded_for |> parse_forwarded_for() |> ensure_ip()

        byte_size(x_forwarded_for) > 0 ->
          x_forwarded_for |> parse_forwarded_for() |> ensure_ip()

        byte_size(forwarded) > 0 ->
          @for_regex
          |> Regex.named_captures(forwarded)
          |> Map.get("for")
          |> String.trim("\"")
          |> clean_ip()
          |> ensure_ip()

        true ->
          format_ip(conn.remote_ip)
      end

    assign(conn, :current_user_ip, remote_ip)
  end

  # Private

  defp ensure_ip(forwarded_ip) when is_binary(forwarded_ip) do
    with {:ok, ip_address} <- InetCidr.parse_address(forwarded_ip),
         true <- public_ip?(ip_address) do
      format_ip(ip_address)
    else
      _ -> nil
    end
  end

  defp format_ip(ip), do: to_string(:inet_parse.ntoa(ip))

  defp public_ip?(ip_address) do
    case ip_address do
      {10, _, _, _} -> false
      {192, 168, _, _} -> false
      {172, second, _, _} when second >= 16 and second <= 31 -> false
      {127, 0, 0, _} -> false
      {_, _, _, _} -> true
      :einval -> false
      _ -> false
    end
  end

  @port_regex ~r/((\.\d+)|(\]))(?<port>:[0-9]+)$/

  defp clean_ip(ip_and_port) when is_binary(ip_and_port) do
    ip =
      case Regex.named_captures(@port_regex, ip_and_port) do
        %{"port" => port} -> String.trim_trailing(ip_and_port, port)
        _ -> ip_and_port
      end

    ip
    |> String.trim_leading("[")
    |> String.trim_trailing("]")
  end

  defp parse_forwarded_for(header) when is_binary(header) do
    header
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> List.first()
    |> clean_ip()
  end
end
