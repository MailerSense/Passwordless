defmodule Passwordless.MagicLink do
  @moduledoc """
  A magic link.
  """

  use Passwordless.Schema, prefix: "mglnk"

  alias Passwordless.EmailMessage
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 12

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
    field :accepted_at, :utc_datetime_usec

    belongs_to :email_message, EmailMessage

    timestamps()
  end

  @fields ~w(
    token
    expires_at
    accepted_at
    email_message_id
  )a
  @required_fields @fields -- [:accepted_at, :email_message_id]

  def changeset(%__MODULE__{} = magic_link, attrs \\ %{}, opts \\ []) do
    magic_link
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_length(:token, is: @size, count: :bytes)
    |> assoc_constraint(:email_message)
    |> unique_constraint(:email_message_id)
    |> unsafe_validate_unique(:email_message_id, Passwordless.Repo, opts)
  end

  # Private

  defp generate_key do
    raw = :crypto.strong_rand_bytes(@size)
    signed = Token.sign(Endpoint, key_salt(), raw)
    {raw, signed}
  end

  defp verify_key(token) when is_binary(token) do
    Token.verify(Endpoint, key_salt(), token)
  end

  defp key_salt, do: Endpoint.config(:secret_key_base)
end
