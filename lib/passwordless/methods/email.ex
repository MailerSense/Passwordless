defmodule Passwordless.Methods.Email do
  @moduledoc """
  An Email method.
  """

  use Passwordless.Schema

  alias Database.ChangesetExt
  alias Passwordless.App
  alias Passwordless.Domain

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: [], adapter_opts: []
  }
  schema "email_methods" do
    field :enabled, :boolean, default: true
    field :expires, :integer, default: 15
    field :sender, :string
    field :sender_name, :string
    field :email_tracking, :boolean, default: false

    belongs_to :app, App, type: :binary_id
    belongs_to :domain, Domain, type: :binary_id

    timestamps()
  end

  @fields ~w(
    enabled
    expires
    sender
    sender_name
    email_tracking
    app_id
    domain_id
  )a
  @required_fields @fields -- [:domain_id]

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_string(:sender_name)
    |> validate_number(:expires, greater_than: 0, less_than_or_equal_to: 60)
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> unique_constraint(:domain_id)
    |> unsafe_validate_unique(:domain_id, Passwordless.Repo)
    |> assoc_constraint(:app)
    |> assoc_constraint(:domain)
  end

  # Private

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> validate_length(field, min: 1, max: 128)
  end
end
