defmodule Passwordless.EmailOptOut do
  @moduledoc """
  An email opt-out.
  """

  use Passwordless.Schema, prefix: "email_opt_out"

  alias Database.ChangesetExt

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :email,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: []
  }
  schema "email_opt_outs" do
    field :email, :string
    field :reason, :string

    timestamps()
  end

  @fields ~w(
    email
    reason
  )a
  @required_fields @fields

  @doc """
  Creates a changeset for the email opt-out.
  """
  def changeset(%__MODULE__{} = email_opt_out, attrs \\ %{}) do
    email_opt_out
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_string(:reason)
    |> validate_email(:email)
    |> unique_constraint(:email)
  end

  # private

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> validate_length(field, min: 1, max: 255)
  end

  defp validate_email(changeset, field) do
    ChangesetExt.validate_email(changeset, field)
  end
end
