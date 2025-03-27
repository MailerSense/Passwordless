defmodule Passwordless.IdempotentCache do
  @moduledoc """
  An idempotent cache for the OneAndDone plug.
  """

  @behaviour OneAndDone.Cache
end
