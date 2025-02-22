defmodule Passwordless.Schema do
  @moduledoc """
  Customized Ecto schema.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      use QueryBuilder

      import Database.SoftDelete.Schema
      import Ecto.Changeset

      @primary_key {:id, UUIDv7, autogenerate: true}
      @timestamps_opts [type: :utc_datetime_usec]
      @foreign_key_type :binary_id
    end
  end
end
