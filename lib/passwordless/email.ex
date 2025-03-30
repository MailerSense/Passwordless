defmodule Passwordless.Email do
  @moduledoc """
  An email.
  """

  use Passwordless.Schema, prefix: "email"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Actor
  alias Passwordless.EmailMessage

  @derive {Jason.Encoder,
           only: [
             :id,
             :address,
             :primary,
             :verified,
             :opted_out_at,
             :inserted_at,
             :updated_at,
             :deleted_at
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "emails" do
    field :address, :string
    field :primary, :boolean, default: false
    field :verified, :boolean, default: false
    field :opted_out, :boolean, virtual: true
    field :opted_out_at, :utc_datetime_usec

    has_many :email_messages, EmailMessage

    belongs_to :actor, Actor

    timestamps()
    soft_delete_timestamp()
  end

  def put_virtuals(%__MODULE__{opted_out_at: opted_out_at} = email) do
    %__MODULE__{email | opted_out: not is_nil(opted_out_at)}
  end

  @fields ~w(
    address
    primary
    verified
    opted_out_at
    actor_id
  )a
  @required_fields @fields -- [:opted_out_at]

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
      query: from(e in __MODULE__, where: e.primary == true),
      prefix: Keyword.get(opts, :prefix),
      error_key: :primary
    )
    |> unsafe_validate_unique([:actor_id, :address], Passwordless.Repo,
      prefix: Keyword.get(opts, :prefix),
      error_key: :address
    )
    |> assoc_constraint(:actor)
  end

  # Private

  defp validate_email(changeset) do
    ChangesetExt.validate_email(changeset, :address)
  end
end
