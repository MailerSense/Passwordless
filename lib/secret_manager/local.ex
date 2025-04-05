defmodule SecretManager.Local do
  @moduledoc """
  Provides a local machine secret manager.
  """

  @behaviour SecretManager.Behaviour

  @impl true
  def get(secret_name, _opts \\ []) do
    value =
      System.get_env()
      |> Enum.filter(fn {key, _} -> String.starts_with?(key, secret_name) end)
      |> Map.new(fn {key, value} -> {String.replace(key, "#{secret_name}_", ""), value} end)
      |> Jason.encode!()

    {:ok, {:secret, secret_name, value}}
  end

  @impl true
  def store(_secret, _opts \\ []) do
    {:error, :not_found}
  end
end
