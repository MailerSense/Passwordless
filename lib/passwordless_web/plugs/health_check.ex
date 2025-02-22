defmodule PasswordlessWeb.Plugs.HealthCheck do
  @moduledoc """
  Routes health check requests
  """

  @behaviour Plug

  import Plug.Conn

  alias Passwordless.HealthCheck

  @impl true
  def init(opts), do: opts

  @doc """
  Check readiness or liveness
  """
  @impl true
  def call(%Plug.Conn{path_info: ["health", "ready"]} = conn, _opts) do
    conn |> check(HealthCheck.check_readiness()) |> halt()
  end

  def call(%Plug.Conn{path_info: ["health", "live"]} = conn, _opts) do
    conn |> check(HealthCheck.check_liveness()) |> halt()
  end

  # Not a healthz request, pass down the chain
  @impl true
  def call(%Plug.Conn{} = conn, _opts), do: conn

  # Private

  defp check(%Plug.Conn{} = conn, :ok), do: send_resp(conn, :ok, "")

  defp check(%Plug.Conn{} = conn, {:error, _error}), do: send_resp(conn, :internal_server_error, "")
end
