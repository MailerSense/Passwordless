defmodule Database.Inet do
  @moduledoc """
  Inet type for Ecto for storing IPs in PostgreSQL.

  Originally from: http://pedroassumpcao.ghost.io/ecto-type-for-ipv4-and-ipv6-addresses/
  """

  @behaviour Ecto.Type

  @impl Ecto.Type
  @doc """
  Defines what internal database type is used.
  """
  def type, do: :inet

  @impl Ecto.Type
  @doc """
  As we don't have any special casting rules, simply pass the value.
  """
  def cast(value), do: {:ok, value}

  @impl Ecto.Type
  @doc """
  Loads the IP as Postgrex.INET structure from the database and coverts to a tuple.
  """
  def load(%Postgrex.INET{address: address}), do: {:ok, address}

  @impl Ecto.Type
  @doc """
  Receives IP as a tuple and converts to Postgrex.INET structure. In case IP is not a tuple,
  returns an error.
  """
  def dump(value) when is_tuple(value) do
    {:ok, %Postgrex.INET{address: value}}
  end

  def dump(value) when is_binary(value) do
    case :inet.parse_address(to_charlist(value)) do
      {:ok, address} -> {:ok, %Postgrex.INET{address: address}}
      {:error, _} -> :error
    end
  end

  def dump(_), do: :error

  @impl Ecto.Type
  def equal?(term1, term2) do
    term1 == term2
  end

  @impl Ecto.Type
  def embed_as(_), do: :self
end

defimpl Jason.Encoder, for: Postgrex.INET do
  def encode(%Postgrex.INET{address: address}, opts) do
    :inet.ntoa(address)
  end
end
