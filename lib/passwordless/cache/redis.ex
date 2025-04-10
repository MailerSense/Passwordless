defmodule Passwordless.Cache.Redis do
  @moduledoc """
  Provides a template for redis cache
  """

  @behaviour Passwordless.Cache.Behaviour

  @redix Passwordless.Cache.Redix

  @impl true
  def get(key) do
    case @redix.command(["GET", key]) do
      {:ok, nil} -> nil
      {:ok, value} -> load(value)
      _ -> :failed
    end
  end

  @impl true
  def put(key, value, opts \\ []) do
    command =
      case Keyword.fetch(opts, :ttl) do
        {:ok, ttl} -> ["SETEX", key, div(ttl, 1000), dump(value)]
        _ -> ["SET", key, dump(value)]
      end

    case @redix.command(command) do
      {:ok, "OK"} -> value
      _ -> :failed
    end
  end

  @impl true
  def delete(nil), do: :ok

  @impl true
  def delete(key) do
    case @redix.command(["DEL", key]) do
      {:ok, _} -> :ok
      _ -> :failed
    end
  end

  @impl true
  def push(key, value) do
    case @redix.command(["LPUSH", key, dump(value)]) do
      {:ok, _} -> :ok
      _ -> :failed
    end
  end

  @impl true
  def pop(key) do
    case @redix.command(["RPOP", key]) do
      {:ok, nil} -> :empty
      {:ok, value} -> {:ok, load(value)}
      _ -> {:error, :failed}
    end
  end

  @impl true
  def exists?(key) do
    case @redix.command(["EXISTS", key]) do
      {:ok, 1} -> true
      {:ok, 0} -> false
      _ -> false
    end
  end

  # Private

  defp load(binary) when is_binary(binary) do
    Plug.Crypto.non_executable_binary_to_term(binary)
  end

  defp dump(entity) do
    :erlang.term_to_binary(entity)
  end
end
