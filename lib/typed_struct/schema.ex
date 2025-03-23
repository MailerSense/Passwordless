defmodule TypedStruct.Schema do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote do
      plugin(TypedStruct.EctoChangeset)
      plugin(TypedStruct.Cast)
    end
  end
end
