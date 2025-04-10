defmodule Passwordless.RateLimit.Redis do
  @moduledoc false

  use Hammer, backend: Hammer.Redis
end
