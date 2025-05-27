defmodule Util.DNS do
  @moduledoc false

  @record_types ~w(a aaaa cname mx soa txt)a

  def resolve(domain, record \\ :a, timeout \\ :timer.seconds(5)) when is_binary(domain) and record in @record_types do
    with {:ok, rec} <- :inet_res.resolve(to_charlist(domain), :in, record, [], timeout),
         {:dns_rec, _header, _query, records, _whut1, _whut2} when is_list(records) <- rec do
      records
      |> Enum.map(&decode_resource/1)
      |> Enum.filter(fn
        {^record, _domain, _ttl, _value} -> true
        _ -> false
      end)
    end
  end

  # Private

  defp decode_resource({:dns_rr, domain, :a = type, _class, _whatever, ttl, ip_addr, _, _, _}) do
    {type, to_string(domain), ttl, :inet.ntoa(ip_addr)}
  end

  defp decode_resource({:dns_rr, domain, :aaaa = type, _class, _whatever, ttl, ip_addr, _, _, _}) do
    {type, to_string(domain), ttl, :inet.ntoa(ip_addr)}
  end

  defp decode_resource({:dns_rr, domain, :mx = type, _class, _whatever, ttl, {prority, server}, _, _, _})
       when is_integer(prority) and is_list(server) do
    {type, to_string(domain), ttl, {prority, to_string(server)}}
  end

  defp decode_resource({:dns_rr, domain, :txt = type, _class, _whatever, ttl, values, _, _, _}) when is_list(values) do
    {type, to_string(domain), ttl, Enum.map(values, &to_string/1)}
  end

  defp decode_resource({:dns_rr, domain, :cname = type, _class, _whatever, ttl, cname, _, _, _}) when is_list(cname) do
    {type, to_string(domain), ttl, to_string(cname)}
  end
end
