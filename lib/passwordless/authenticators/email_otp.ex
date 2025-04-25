defmodule Passwordless.Authenticators.EmailOTP do
  @moduledoc """
  An Email authenticator.
  """

  use Passwordless.Schema, prefix: "emailotp"

  alias Database.ChangesetExt
  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.EmailTemplate

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "email_otp_authenticators" do
    field :enabled, :boolean, default: true
    field :expires, :integer, default: 5
    field :resend, :integer, default: 30
    field :sender, :string
    field :sender_name, :string

    belongs_to :app, App
    belongs_to :email_template, EmailTemplate

    timestamps()
  end

  @doc """
  The sender email address.
  """
  def sender_email(%__MODULE__{sender: sender}, %Domain{} = domain) do
    "#{sender}#{Domain.email_suffix(domain)}"
  end

  @fields ~w(
    enabled
    expires
    resend
    sender
    sender_name
    app_id
    email_template_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}, opts \\ []) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_sender(opts)
    |> validate_string(:sender_name)
    |> validate_number(:expires, greater_than: 0, less_than_or_equal_to: 60)
    |> validate_number(:resend, greater_than_or_equal_to: 30, less_than_or_equal_to: 300)
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
    |> assoc_constraint(:email_template)
  end

  # Private

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> ChangesetExt.validate_profanities(field)
    |> validate_length(field, min: 1, max: 64)
  end

  defp validate_sender(changeset, opts) do
    case Keyword.get(opts, :domain) do
      %Domain{purpose: :email} = domain ->
        changeset =
          if Domain.system?(domain),
            do: put_change(changeset, :sender, "verify"),
            else: changeset

        ChangesetExt.validate_email(changeset, :sender, suffix: domain.name)

      _ ->
        changeset
    end
  end
end
