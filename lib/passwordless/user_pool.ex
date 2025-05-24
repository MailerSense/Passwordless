defmodule Passwordless.UserPool do
  @moduledoc """
  A user pool.
  """

  use Passwordless.Schema, prefix: "user_pool"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Database.Tenant
  alias Passwordless.App
  alias Passwordless.User
  alias Passwordless.UserPoolMembership

  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  schema "user_pools" do
    field :name, :string
    field :alias, :string

    many_to_many :users, User, join_through: UserPoolMembership, unique: true

    timestamps()
  end

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, prefix: ^Tenant.to_prefix(app)
  end

  @fields ~w(name)a
  @required_fields @fields

  @doc """
  A user second factor changeset.
  """
  def changeset(%__MODULE__{} = user_pool, attrs \\ %{}, opts \\ []) do
    user_pool
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> name_to_alias(opts)
    |> validate_alias(opts)
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 64)
  end

  defp name_to_alias(changeset, opts) do
    case get_change(changeset, :name) do
      name when is_binary(name) ->
        code_alias = Recase.to_camel(name)

        code_alias =
          Util.generate_until(
            code_alias,
            fn _prev -> code_alias <> Util.random_numeric_string(2) end,
            fn code_alias ->
              Passwordless.Repo.exists?(
                from __MODULE__,
                  prefix: ^Keyword.get(opts, :prefix, "public"),
                  where: [alias: ^code_alias]
              )
            end
          )

        put_change(changeset, :alias, code_alias)

      _ ->
        changeset
    end
  end

  defp validate_alias(changeset, opts) do
    changeset
    |> validate_required(:alias)
    |> ChangesetExt.ensure_trimmed(:alias)
    |> validate_length(:alias, min: 1, max: 64)
    |> unique_constraint(:alias)
    |> unsafe_validate_unique(:alias, Passwordless.Repo, opts)
  end
end
