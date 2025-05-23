defmodule Passwordless.SecretManager.Vault do
  @moduledoc """
  A central store of secrets fetched from a JSON secret in Passwordless.SecretManager.
  """

  use GenServer

  @table :secret_vault
  @interval :timer.minutes(30)

  def start_link(secret_name) do
    GenServer.start_link(__MODULE__, secret_name, name: __MODULE__)
  end

  def get(name) do
    key = {__MODULE__, name}

    case :ets.lookup(@table, key) do
      [{^key, value}] when is_binary(value) -> value
      _ -> nil
    end
  end

  # Server

  @impl true
  def init(secret_name) do
    if :ets.info(@table) == :undefined do
      :ets.new(@table, [
        :set,
        :named_table,
        :protected,
        read_concurrency: true,
        write_concurrency: false
      ])
    end

    refresh_secret(secret_name)

    tick()

    {:ok, secret_name}
  end

  @impl true
  def handle_info(:tick, secret_name) do
    refresh_secret(secret_name)

    tick()

    {:noreply, secret_name}
  end

  # Private

  defp tick, do: Process.send_after(self(), :tick, @interval)

  defp refresh_secret(secret_name) do
    with {:ok, {:secret, _name, raw_body}} <- Passwordless.SecretManager.get(secret_name),
         {:ok, json_body} <- Jason.decode(raw_body) do
      Enum.each(json_body, fn
        {key, value} when is_binary(key) and is_binary(value) ->
          value =
            case Base.decode64(value) do
              {:ok, decoded_value} -> decoded_value
              _ -> value
            end

          :ets.insert(@table, {{__MODULE__, key}, value})

        _ ->
          nil
      end)
    else
      error ->
        raise "Failed to fetch secret #{secret_name}: #{inspect(error)}"
    end
  end
end
