defmodule RateLimit.ETS do
  @moduledoc false

  use Hammer, backend: :ets
end
