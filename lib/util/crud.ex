defmodule Util.Crud do
  @moduledoc false

  defmacro crud(key, assoc, mod) do
    quote do
      alias Passwordless.App
      alias Passwordless.Repo

      def unquote(:"get_#{key}")(%App{} = app, id) when is_binary(id) do
        app
        |> Ecto.assoc(unquote(assoc))
        |> Repo.get(id)
      end

      def unquote(:"get_#{key}!")(%App{} = app, id) when is_binary(id) do
        app
        |> Ecto.assoc(unquote(assoc))
        |> Repo.get!(id)
      end

      def unquote(:"create_#{key}")(%App{} = app, attrs \\ %{}, opts \\ []) do
        app
        |> Ecto.build_assoc(unquote(assoc))
        |> unquote(mod).changeset(attrs, opts)
        |> Repo.insert()
      end

      def unquote(:"update_#{key}")(%unquote(mod){} = val, attrs \\ %{}, opts \\ []) do
        val
        |> unquote(mod).changeset(attrs, opts)
        |> Repo.update()
      end

      def unquote(:"change_#{key}")(%unquote(mod){} = val, attrs \\ %{}, opts \\ []) do
        if Ecto.get_meta(val, :state) == :loaded do
          unquote(mod).changeset(val, attrs, opts)
        else
          unquote(mod).changeset(val, attrs, opts)
        end
      end

      def unquote(:"delete_#{key}")(%unquote(mod){} = val) do
        Repo.soft_delete(val)
      end
    end
  end
end
