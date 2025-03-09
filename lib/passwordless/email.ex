defmodule Passwordless.Email do
  @moduledoc """
  An email.
  """

  use Passwordless.Schema

  alias Database.ChangesetExt
  alias Passwordless.Actor

  @derive {Jason.Encoder,
           only: [
             :id,
             :address,
             :primary,
             :verified
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "emails" do
    field :address, :string
    field :primary, :boolean, default: false
    field :verified, :boolean, default: false

    belongs_to :actor, Actor, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    address
    primary
    verified
    actor_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}, opts \\ []) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_email()
    |> unique_constraint([:actor_id, :primary], error_key: :primary)
    |> unique_constraint([:actor_id, :address], error_key: :address)
    |> unsafe_validate_unique([:actor_id, :primary], Passwordless.Repo,
      error_key: :primary,
      prefix: Keyword.get(opts, :prefix)
    )
    |> unsafe_validate_unique([:actor_id, :address], Passwordless.Repo,
      error_key: :address,
      prefix: Keyword.get(opts, :prefix)
    )
    |> assoc_constraint(:actor)
  end

  # Private

  defp validate_email(changeset) do
    ChangesetExt.validate_email(changeset, :address)
  end
end
