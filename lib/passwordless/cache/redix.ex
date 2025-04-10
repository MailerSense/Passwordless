defmodule Passwordless.Cache.Redix do
  @moduledoc """
  Manages redis connection pool
  """

  @pool_size 10

  def child_spec(args) do
    children =
      for index <- 0..(@pool_size - 1) do
        a = Keyword.put(args, :name, worker_name(index))
        Supervisor.child_spec({Redix, a}, id: {Redix, index})
      end

    %{
      id: Passwordless.Cache.RedisSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  def command(command) do
    random_index() |> worker_name() |> Redix.command(command)
  end

  # Private

  defp random_index, do: Enum.random(0..(@pool_size - 1))

  defp worker_name(id), do: :"redix_#{id}"
end
