defmodule Util.Bin do
  @moduledoc false

  def wire(true), do: <<1>>
  def wire(false), do: <<0>>
  def wire(int) when is_integer(int), do: Integer.to_string(int)
  def wire(bin) when is_binary(bin), do: bin
  def wire(list) when is_list(list), do: start() <> Enum.map_join(list, sep(), &wire/1) <> finish()
  def wire(nil), do: <<-1>>
  def wire(_), do: <<-1>>

  def wire_map(list, f) when is_list(list) and is_function(f, 1), do: start() <> Enum.map_join(list, sep(), f) <> finish()

  def start, do: <<?<>>
  def finish, do: <<?>>>
  def sep, do: <<?:>>
end
