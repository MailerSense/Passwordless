defmodule Passwordless.SwearJarBlocklist do
  @moduledoc """
  Loads the swear word blocklist.
  """

  for file <-
        :passwordless
        |> :code.priv_dir()
        |> Path.join("naughty")
        |> Path.join("*.txt")
        |> Path.wildcard() do
    name = file |> Path.basename(".txt") |> String.to_atom()

    regex =
      file
      |> File.read!()
      |> String.split("\n")
      |> Stream.map(&String.trim/1)
      |> Stream.filter(fn line -> line != "" end)
      |> Stream.map(&String.replace(&1, ~r/^"\s*|\s*"$/, ""))
      |> Enum.map_join("|", &Regex.escape/1)
      |> Kernel.then(&"\\b(?:#{&1})\\b")
      |> Regex.compile!("iu")

    @doc """
    Provides a regex for checking the #{name} blocklist
    """
    def unquote(name)(), do: unquote(Macro.escape(regex))
  end
end
