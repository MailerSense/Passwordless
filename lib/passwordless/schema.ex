defmodule Passwordless.Schema do
  @moduledoc """
  Customized Ecto schema.
  """

  defmacro __using__(opts \\ []) do
    prefix = Keyword.fetch!(opts, :prefix)

    quote do
      use Ecto.Schema
      use QueryBuilder

      import Database.SoftDelete.Schema
      import Ecto.Changeset

      @type t :: %__MODULE__{}

      @spec prefix() :: binary()
      def prefix, do: unquote(prefix)

      @primary_key {:id, Database.PrefixedUUID, prefix: unquote(prefix), autogenerate: true}
      @timestamps_opts [type: :utc_datetime_usec]
      @foreign_key_type Database.PrefixedUUID
    end
  end
end
