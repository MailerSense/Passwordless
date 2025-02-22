defmodule Util do
  @moduledoc """
  A set of utility functions for use all over the project.
  """

  @doc """
  Useful for printing maps onto the page during development. Or passing a map to a hook
  """
  def to_json(nil), do: "-"

  def to_json(obj) do
    Jason.encode!(obj, pretty: true)
  end

  @doc """
  Generate a truncated JSON string from a map or other object.
  """
  def to_truncated_json(map) when is_map(map) and map_size(map) > 0 do
    map
    |> Map.to_list()
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.take(1)
    |> Map.new()
    |> Jason.encode!(pretty: true)
  end

  def to_truncated_json(obj), do: to_json(obj)

  def string_equals?(a, b) do
    a =
      case a do
        nil -> nil
        a when is_atom(a) -> Atom.to_string(a)
        a when is_binary(a) -> a
      end

    b =
      case b do
        nil -> nil
        b when is_atom(b) -> Atom.to_string(b)
        b when is_binary(b) -> b
      end

    a == b
  end

  @doc """
  Get a random string of given length.
  Returns a random url safe encoded64 string of the given length.
  Used to generate tokens for the various modules that require unique tokens.
  """
  def random_string(length \\ 16) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
    |> String.replace(["+", "/", "-"], "_")
    |> binary_part(0, length)
  end

  @doc """
  Get a random numeric string of given length.
  """
  def random_numeric_string(length \\ 10) do
    length
    |> :crypto.strong_rand_bytes()
    |> :crypto.bytes_to_integer()
    |> Integer.to_string()
    |> binary_part(0, length)
  end

  @doc """
  Imitates .compact in Ruby... removes nil values from an array https://ruby-doc.org/core-1.9.3/Array.html#method-i-compact

  ## Examples

      iex> compact([1, 2, nil, 3, nil, 4])
      [1, 2, 3, 4]
  """
  def compact(list), do: Enum.filter(list, &(!is_nil(&1)))

  def email_valid?(email) do
    Util.Email.valid?(email)
  end

  def email_format?(email) do
    Util.Email.valid?(email, [:format, :domain, :burner])
  end

  @doc """
  Evaluates if a value is blank. Returns true if the value is nil, an empty string, or an empty list.

  ## Examples

      iex> blank?(nil)
      true
      iex> blank?("")
      true
      iex> blank?([])
      true
      iex> blank?([1])
      false
      iex> blank?("Hello")
      false
  """

  def blank?(term) do
    Blankable.blank?(term)
  end

  @doc "Opposite of blank?"
  def present?(term) do
    !Blankable.blank?(term)
  end

  @doc "Check if a map has atoms as keys"
  def map_has_atom_keys?(map) do
    map
    |> Map.keys()
    |> List.first()
    |> is_atom()
  end

  @doc """

  ## Examples

      iex> format_money(123456)
      "$1,234.56"
  """
  def format_money(cents, currency \\ "USD") do
    CurrencyFormatter.format(cents, currency)
  end

  @doc "Trim whitespace on either end of a string. Account for nil"

  def trim(str) when is_binary(str), do: String.trim(str)
  def trim(str), do: str

  def trim_downcase(str) when is_binary(str), do: String.downcase(String.trim(str))
  def trim_downcase(str), do: str

  @doc "Useful for when you have an array of strings coming in from a user form"
  def trim_strings_in_array(array) do
    array
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&present?/1)
  end

  @doc """
  ## Examples:

      iex> Util.truncate("This is a very long string", 15)
      "This is a ve..."
  """
  def truncate(text, count \\ 10) do
    Util.StringExt.truncate(text, length: count)
  end

  @doc """
  ## Examples:

      iex> number_with_delimiter(1000)
      "1,000"
      iex> number_with_delimiter(1000000)
      "1,000,000"
  """
  def number_with_delimiter(i) when is_binary(i), do: number_with_delimiter(String.to_integer(i))

  def number_with_delimiter(i) when is_integer(i) do
    i
    |> Integer.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3, 3, [])
    |> Enum.join(",")
    |> String.reverse()
  end

  def unix_to_datetime(datetime_in_seconds) when is_integer(datetime_in_seconds) and datetime_in_seconds > 0 do
    DateTime.from_unix!(datetime_in_seconds)
  end

  def unix_to_datetime(_datetime_in_seconds), do: nil

  @doc """
  For updating a database object in a list of database objects.
  The object must have an ID and exist in the list
  eg. users = Util.replace_object_in_list(users, updated_user)
  """
  def replace_object_in_list(list, object) do
    put_in(
      list,
      [Access.filter(&(&1.id == object.id))],
      object
    )
  end

  def deep_struct_to_map(%{} = map), do: convert(map)

  def deep_struct_to_map(nil), do: nil

  defp convert(data) when is_struct(data) do
    data |> Map.from_struct() |> convert()
  end

  defp convert(data) when is_map(data) do
    for {key, value} <- data, reduce: %{} do
      acc ->
        case key do
          :__meta__ ->
            acc

          other when is_atom(other) ->
            Map.put(acc, Atom.to_string(other), convert(value))

          other when is_binary(other) ->
            Map.put(acc, other, convert(value))
        end
    end
  end

  defp convert(other), do: other

  @doc """
  Conditionally puts a key-value pair into a map, only if the value is not nil.

  ## Examples

      iex> maybe_put(%{}, :name, "John")
      %{name: "John"}

      iex> maybe_put(%{name: "Mary"}, :name, "John")
      %{name: "John"}

      iex> maybe_put(%{name: "John"}, :name, nil)
      %{name: "John"}

  """
  def maybe_put(attrs, _key, nil), do: attrs
  def maybe_put(attrs, key, value), do: Map.put(attrs, key, value)

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  def cast_property_map(map) when is_map(map) do
    map
    |> Enum.filter(fn {k, v} -> is_binary(k) and is_simple_type(v) end)
    |> Map.new(fn {k, v} -> {k, cast_simple_property(v)} end)
  end

  def cast_property_map(value), do: value

  def cast_simple_property("true"), do: true
  def cast_simple_property("false"), do: false
  def cast_simple_property(value), do: value

  def validate_property_map(map) when is_map(map) do
    Enum.all?(map, fn {k, v} -> (is_binary(k) or is_atom(k)) and is_simple_type(v) end)
  end

  @max_string_length 1024

  def is_simple_type(v) when is_integer(v) or is_float(v) or is_boolean(v), do: true
  def is_simple_type(v) when is_binary(v), do: String.length(v) <= @max_string_length
  def is_simple_type(v) when is_list(v), do: Enum.filter(v, fn v -> not is_list(v) and is_simple_type(v) end)
  def is_simple_type(_), do: false

  @doc """
  Use for when you want to combine all form errors into one message (maybe to display in a flash)
  """
  def humanize_changeset_errors(%Ecto.Changeset{} = changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn
          {key, {:parameterized, Ecto.Enum, %{mappings: mappings}}}, acc ->
            String.replace(acc, "%{#{key}}", "Must be one of #{Enum.join(Keyword.values(mappings), ", ")}")

          {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    Map.new(errors, fn {key, errors} ->
      {Phoenix.Naming.humanize(key), Enum.join(errors, ", ")}
    end)
  end

  @duplicate_regex ~r/^(?<name>.+)\((?<index>\d+)\)$/

  def duplicate_name(name) when is_binary(name) do
    case Regex.named_captures(@duplicate_regex, name) do
      %{"name" => name, "index" => index} -> String.trim(name) <> " (#{String.to_integer(index) + 1})"
      _ -> String.trim(name) <> " (1)"
    end
  end

  def capitalize_sentence(sentence) when is_binary(sentence) do
    sentence
    |> String.split()
    |> Enum.map_join(" ", &:string.titlecase/1)
  end

  def slice_central(string, n) when is_binary(string) and is_integer(n) and n > 0 do
    len = String.length(string)
    start_pos = div(len - n, 2) + 1
    String.slice(string, start_pos, n)
  end

  def to_bool(true), do: true
  def to_bool(false), do: false
  def to_bool(nil), do: false
  def to_bool("t"), do: true
  def to_bool("true"), do: true
  def to_bool("on"), do: true
  def to_bool("y"), do: true
  def to_bool("yes"), do: true
  def to_bool("1"), do: true

  @truthy_values ~w(t true on y yes 1)

  def to_bool(string) when is_binary(string) do
    string =
      string
      |> String.trim()
      |> String.downcase()

    Enum.member?(@truthy_values, string)
  end

  def to_bool(0), do: false
  def to_bool(integer) when is_integer(integer) and not is_nil(integer) and integer > 0, do: true
  def to_bool(_), do: false

  # Streams

  def generate_until(start_value, value_fun, cond_fun, opts \\ [])
      when is_function(value_fun, 1) and is_function(cond_fun, 1) do
    start_value
    |> Stream.iterate(value_fun)
    |> Stream.take(Keyword.get(opts, :times, 5))
    |> Enum.reduce_while(nil, fn item, _acc ->
      if cond_fun.(item),
        do: {:cont, item},
        else: {:halt, item}
    end)
  end

  @excluded_time_unites ~w(second seconds millisecond milliseconds)

  def format_readable_duration(%Timex.Duration{} = duration) do
    duration
    |> Timex.Format.Duration.Formatters.Humanized.format()
    |> String.split(", ")
    |> Enum.reject(fn s -> Enum.any?(@excluded_time_unites, &String.ends_with?(s, &1)) end)
    |> Enum.join(" ")
  end

  # Private

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, %{} = left, %{} = right) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, left, nil) when is_struct(left) do
    left
  end

  defp deep_resolve(_key, _left, right) do
    right
  end
end
