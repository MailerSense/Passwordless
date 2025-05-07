defmodule Passwordless.Identifier do
  @moduledoc """
  An identifier.
  """

  use Passwordless.Schema, prefix: "ident"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.User

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :value,
      :primary,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "identifiers" do
    field :value, :string
    field :primary, :boolean, default: false

    belongs_to :user, User

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    value
    primary
    user_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = identifier, attrs \\ %{}, opts \\ []) do
    identifier
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_value()
    |> unique_constraint(:value)
    |> unique_constraint([:user_id, :primary], error_key: :primary)
    |> unsafe_validate_unique(:value, Passwordless.Repo, opts)
    |> unsafe_validate_unique([:user_id, :primary], Passwordless.Repo,
      query: from(i in __MODULE__, where: i.primary),
      prefix: Keyword.get(opts, :prefix),
      error_key: :primary
    )
    |> assoc_constraint(:user)
  end

  # Private

  defp validate_value(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:value)
    |> validate_length(:value, min: 1, max: 255)
  end
end
