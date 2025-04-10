defmodule Passwordless.Cache.InMemory do
  @moduledoc """
  Provides a template for in-memory cache
  """

  @behaviour Passwordless.Cache.Behaviour

  @cache :in_memory_cache

  def name, do: @cache

  @impl true
  def get(key) do
    case Cachex.get(@cache, key) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  @impl true
  def put(key, value, opts \\ []) do
    case Cachex.put(@cache, key, value, opts) do
      {:ok, _} -> value
      _ -> nil
    end
  end

  @impl true
  def delete(key) do
    Cachex.del(@cache, key)
    :ok
  end

  @impl true
  def push(_key, _value) do
    raise "Not supported"
  end

  @impl true
  def pop(_key) do
    raise "Not supported"
  end

  @impl true
  def exists?(key) do
    case Cachex.exists?(@cache, key) do
      {:ok, exists} -> exists
      _ -> false
    end
  end
end
