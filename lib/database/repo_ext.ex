defmodule Database.RepoExt do
  @moduledoc """
  Utilities for Ecto repos.
  """

  defmacro __using__(_) do
    quote do
      import Ecto.Query
    end
  end
end
