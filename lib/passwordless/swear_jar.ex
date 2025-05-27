defmodule Passwordless.SwearJar do
  @moduledoc """
  A simple profanity detector.
  """

  @english Passwordless.SwearJarBlocklist.english()

  @doc """
  Checks if the given string contains any profane words based on the provided regex.
  """
  def profane?(string, regex \\ @english) when is_binary(string) do
    Regex.match?(regex, string)
  end

  @doc """
  Returns a list of possible profanities found in the given string.
  """
  def profanities(string, regex \\ @english) when is_binary(string) do
    regex
    |> Regex.scan(string)
    |> Enum.map(fn [match] -> match end)
    |> Enum.uniq()
  end
end
