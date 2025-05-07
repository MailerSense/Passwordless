defmodule Passwordless.Email do
  @moduledoc """
  An email.
  """

  use Passwordless.Schema, prefix: "email"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.EmailMessage
  alias Passwordless.User

  @authenticators ~w(email_otp magic_link)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :address,
      :primary,
      :verified,
      :opted_out_at,
      :authenticators,
      :inserted_at,
      :updated_at
    ]
  }
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
    field :authenticators, {:array, Ecto.Enum}, values: @authenticators, default: []

    has_many :email_messages, EmailMessage, preload_order: [asc: :inserted_at]

    belongs_to :user, User

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Checks if the email has opted out.
  """
  def opted_out?(%__MODULE__{opted_out_at: %DateTime{}}), do: true
  def opted_out?(%__MODULE__{}), do: false

  @doc """
  Put virtual fields.
  """
  def put_virtuals(%__MODULE__{opted_out_at: opted_out_at} = email) do
    %__MODULE__{email | opted_out: not is_nil(opted_out_at)}
  end

  @fields ~w(
    address
    primary
    verified
    opted_out_at
    authenticators
    user_id
  )a
  @required_fields @fields -- [:opted_out_at]

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = email, attrs \\ %{}, opts \\ []) do
    email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_email()
    |> validate_authenticators()
    |> unique_constraint(:address)
    |> unique_constraint([:user_id, :primary], error_key: :primary)
    |> unsafe_validate_unique(:address, Passwordless.Repo, opts)
    |> unsafe_validate_unique([:user_id, :primary], Passwordless.Repo,
      query: from(e in __MODULE__, where: e.primary),
      prefix: Keyword.get(opts, :prefix),
      error_key: :primary
    )
    |> assoc_constraint(:user)
  end

  # Private

  defp validate_email(changeset) do
    ChangesetExt.validate_email(changeset, :address)
  end

  defp validate_authenticators(changeset) do
    ChangesetExt.clean_array(changeset, :authenticators)
  end
end
