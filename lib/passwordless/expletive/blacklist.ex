defmodule Passwordless.Expletive.Blacklist do
  @moduledoc """
  A module to load and provide access to a list of profane words.
  """

  data_dir = Path.join([:code.priv_dir(:passwordless), "naughty", "*.txt"])

  strip_quotes = fn word -> String.replace(word, ~r/^"\s*|\s*"$/, "") end

  for file <- Path.wildcard(data_dir) do
    fun_name = file |> Path.basename(".txt") |> String.to_atom()

    words =
      file
      |> File.read!()
      |> String.split("\n")
      |> Stream.map(&String.trim/1)
      |> Stream.filter(fn line -> line != "" end)
      |> Enum.map(strip_quotes)

    @doc "Returns #{fun_name} words to blacklist"
    def unquote(fun_name)(), do: unquote(words)
  end
end
