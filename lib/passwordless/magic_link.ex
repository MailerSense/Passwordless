defmodule Passwordless.MagicLink do
  @moduledoc """
  A magic link.
  """

  use Passwordless.Schema, prefix: "mglnk"

  alias Passwordless.EmailMessage

  @size 16

  @derive {Jason.Encoder,
           only: [
             :id,
             :expires_at,
             :accepted_at
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "magic_links" do
    field :token, Passwordless.EncryptedBinary
    field :expires_at, :utc_datetime_usec
    field :expires_in, :integer, virtual: true
    field :accepted_at, :utc_datetime_usec

    belongs_to :email_message, EmailMessage

    timestamps()
  end

  @fields ~w(
    token
    expires_in
    expires_at
    accepted_at
    email_message_id
  )a
  @required_fields @fields -- [:expires_in, :accepted_at, :email_message_id]

  def changeset(%__MODULE__{} = magic_link, attrs \\ %{}, opts \\ []) do
    magic_link
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_length(:token, is: @size, count: :bytes)
    |> assoc_constraint(:email_message)
    |> unique_constraint(:email_message_id)
    |> unsafe_validate_unique(:email_message_id, Passwordless.Repo)
  end
end
