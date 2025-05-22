defmodule Database.PrefixedUUID do
  @moduledoc false
  use Ecto.ParameterizedType

  @doc """
  Generates prefixed base62 encoded UUIDv7.

  ## Examples

      @primary_key {:id, Database.PrefixedUUID, prefix: "acct", autogenerate: true}
      @foreign_key_type Database.PrefixedUUID
  """
  @impl true
  def init(opts) do
    schema = Keyword.fetch!(opts, :schema)
    field = Keyword.fetch!(opts, :field)
    uniq = Uniq.UUID.init(schema: schema, field: field, version: 7, default: :raw, dump: :raw)

    case opts[:primary_key] do
      true ->
        prefix = Keyword.get(opts, :prefix) || raise "`:prefix` option is required"

        %{
          primary_key: true,
          schema: schema,
          prefix: prefix,
          uniq: uniq
        }

      _any ->
        %{
          schema: schema,
          field: field,
          uniq: uniq
        }
    end
  end

  @impl true
  def type(_params), do: :uuid

  @impl true
  def cast(nil, _params), do: {:ok, nil}

  def cast(data, params) do
    with {:ok, prefix, _uuid} <- slug_to_uuid(data),
         {prefix, prefix} <- {prefix, prefix(params)} do
      {:ok, data}
    else
      _ -> :error
    end
  end

  @slug_regex ~r/^(?<prefix>[a-z_]+)_(?<id>[a-zA-Z0-9]{22,36})$/

  def slug_to_uuid(string) do
    with %{"id" => slug, "prefix" => prefix} <- Regex.named_captures(@slug_regex, string),
         {:ok, uuid} <- decode_base62_uuid(slug) do
      {:ok, prefix, uuid}
    else
      _ -> :error
    end
  end

  defp prefix(%{primary_key: true, prefix: prefix}), do: prefix

  # If we deal with a belongs_to assocation we need to fetch the prefix from
  # the associations schema module
  defp prefix(%{schema: schema, field: field}) do
    %{related: schema, related_key: field} = schema.__schema__(:association, field)

    case schema.__schema__(:type, field) do
      {:parameterized, __MODULE__, %{prefix: prefix}} -> prefix
      {:parameterized, {__MODULE__, %{prefix: prefix}}} -> prefix
    end
  end

  @impl true
  def load(data, loader, params) do
    case Uniq.UUID.load(data, loader, params.uniq) do
      {:ok, nil} -> {:ok, nil}
      {:ok, uuid} -> {:ok, uuid_to_slug(uuid, params)}
      :error -> :error
    end
  end

  def uuid_to_slug(uuid, params) do
    "#{prefix(params)}_#{encode_base62_uuid(uuid)}"
  end

  @impl true
  def dump(nil, _, _), do: {:ok, nil}

  def dump(slug, dumper, params) do
    case slug_to_uuid(slug) do
      {:ok, _prefix, uuid} -> Uniq.UUID.dump(uuid, dumper, params.uniq)
      :error -> :error
    end
  end

  @impl true
  def autogenerate(params) do
    uuid_to_slug(Uniq.UUID.autogenerate(params.uniq), params)
  end

  @impl true
  def embed_as(format, params), do: Uniq.UUID.embed_as(format, params.uniq)

  @impl true
  def equal?(nil, nil, _params), do: true
  def equal?(_a, nil, _params), do: false
  def equal?(nil, _b, _params), do: false

  def equal?(a, b, params) do
    with {:ok, prefix, uuid_a} <- slug_to_uuid(a),
         {:ok, ^prefix, uuid_b} <- slug_to_uuid(b) do
      Uniq.UUID.equal?(uuid_a, uuid_b, params.uniq)
    else
      _ -> Uniq.UUID.equal?(a, b, params.uniq)
    end
  end

  # UUID Base62 encoder/decoder

  @base62_uuid_length 22
  @uuid_length 32

  defp encode_base62_uuid(uuid) do
    uuid
    |> String.replace("-", "")
    |> String.to_integer(16)
    |> base62_encode()
    |> String.pad_leading(@base62_uuid_length, "0")
  end

  defp decode_base62_uuid(string) do
    with {:ok, number} <- base62_decode(string) do
      number_to_uuid(number)
    end
  end

  defp number_to_uuid(number) do
    number
    |> Integer.to_string(16)
    |> String.downcase()
    |> String.pad_leading(@uuid_length, "0")
    |> case do
      <<g1::binary-size(8), g2::binary-size(4), g3::binary-size(4), g4::binary-size(4), g5::binary-size(12)>> ->
        {:ok, "#{g1}-#{g2}-#{g3}-#{g4}-#{g5}"}

      other ->
        {:error, "got invalid base62 uuid; #{inspect(other)}"}
    end
  end

  # Base62 encoder/decoder
  @base62_alphabet ~c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

  for {digit, idx} <- Enum.with_index(@base62_alphabet) do
    defp base62_encode(unquote(idx)), do: unquote(<<digit>>)
  end

  defp base62_encode(number) do
    base62_encode(div(number, unquote(length(@base62_alphabet)))) <>
      base62_encode(rem(number, unquote(length(@base62_alphabet))))
  end

  defp base62_decode(string) do
    string
    |> String.split("", trim: true)
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, {0, 0}}, fn char, {:ok, {acc, step}} ->
      case decode_base62_char(char) do
        {:ok, number} ->
          {:cont, {:ok, {acc + number * Integer.pow(unquote(length(@base62_alphabet)), step), step + 1}}}

        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, {number, _step}} -> {:ok, number}
      {:error, error} -> {:error, error}
    end
  end

  for {digit, idx} <- Enum.with_index(@base62_alphabet) do
    defp decode_base62_char(unquote(<<digit>>)), do: {:ok, unquote(idx)}
  end

  defp decode_base62_char(char), do: {:error, "got invalid base62 character; #{inspect(char)}"}
end
