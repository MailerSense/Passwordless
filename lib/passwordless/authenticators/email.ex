defmodule Passwordless.Authenticators.Email do
  @moduledoc """
  An Email authenticator.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.EmailTemplate
  alias Passwordless.Repo

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "email_authenticators" do
    field :enabled, :boolean, default: true
    field :expires, :integer, default: 15
    field :sender, :string
    field :sender_name, :string
    field :email_tracking, :boolean, default: true

    belongs_to :app, App, type: :binary_id
    belongs_to :domain, Domain, type: :binary_id
    belongs_to :email_template, EmailTemplate, type: :binary_id

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
    email_template_id
  )a
  @required_fields @fields -- [:domain_id]

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_sender()
    |> validate_string(:sender_name)
    |> validate_number(:expires, greater_than: 0, less_than_or_equal_to: 60)
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> unique_constraint(:domain_id)
    |> unsafe_validate_unique(:domain_id, Passwordless.Repo)
    |> assoc_constraint(:app)
    |> assoc_constraint(:domain)
    |> assoc_constraint(:email_template)
  end

  # Private

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> validate_length(field, min: 1, max: 255)
  end

  defp validate_sender(changeset) do
    with domain_id when is_binary(domain_id) <- get_field(changeset, :domain_id),
         domain_name when is_binary(domain_name) <-
           Repo.one(from(d in Domain, where: d.id == ^domain_id, select: d.name)) do
      ChangesetExt.validate_email(changeset, :sender, suffix: domain_name)
    else
      _ -> changeset
    end
  end
end
