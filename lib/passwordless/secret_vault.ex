defmodule Passwordless.SecretVault do
  @moduledoc false

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
    :ets.new(@table, [
      :set,
      :named_table,
      :public,
      read_concurrency: true,
      write_concurrency: false
    ])

    {:ok, secret_name, {:continue, :load_secret}}
  end

  @impl true
  def handle_continue(:load_secret, secret_name) do
    refresh_secret(secret_name)

    tick()

    {:noreply, secret_name}
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
    with {:ok, {:secret, _name, raw_body}} <- SecretManager.get(secret_name),
         {:ok, json_body} <- Jason.decode(raw_body) do
      Enum.each(json_body, fn
        {key, value} when is_binary(key) and is_binary(value) ->
          :ets.insert(@table, {{__MODULE__, key}, value})

        _ ->
          nil
      end)
    end
  end
end
