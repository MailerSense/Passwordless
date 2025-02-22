defmodule Passwordless.Health do
  @moduledoc """
  Used for executing DB health tasks when run in production without Mix
  installed.
  """

  @port 8000
  @host "localhost"

  def check do
    :inets.start()

    case :httpc.request("http://#{@host}:#{@port}/health/live") do
      {:ok, {{_, 200, _}, _, _}} -> nil
      _ -> exit(:unhealthy)
    end
  end
end
