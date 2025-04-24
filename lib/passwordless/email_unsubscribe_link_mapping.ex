defmodule Passwordless.EmailUnsubscribeLinkMapping do
  @moduledoc """
  An email unsubscribe link mapping.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Passwordless.App
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 16
  @primary_key false
  @timestamps_opts [type: :utc_datetime]
  @foreign_key_type Database.PrefixedUUID

  schema "email_unsubscribe_link_mappings" do
    field :token, :binary, primary_key: true, redact: true
    field :email_id, :binary_id

    belongs_to :app, App

    timestamps(updated_at: false)
  end

  @fields ~w(
    token
    email_id
    app_id
  )a

  @required_fields @fields

  @doc """
  A mapping changeset.
  """
  def changeset(%__MODULE__{} = message_mapping, attrs \\ %{}) do
    message_mapping
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> decode_email_id()
    |> unique_constraint(:email_id)
    |> assoc_constraint(:app)
  end

  @doc """
  Get the mapping by signed token.
  """
  def get_by_token(token_signed) when is_binary(token_signed) do
    with {:ok, token} <- verify_token(token_signed) do
      {:ok,
       from(
         m in __MODULE__,
         where: m.token == ^token,
         left_join: a in assoc(m, :app),
         select: {m, a}
       )}
    end
  end

  @doc """
  Sign the mapping token.
  """
  def sign_token(%__MODULE__{token: token}) when is_binary(token) do
    Token.sign(Endpoint, key_salt(), token)
  end

  @doc """
  Generate a random token.
  """
  def generate_token do
    :crypto.strong_rand_bytes(@size)
  end

  # Private

  defp decode_email_id(changeset) do
    update_change(changeset, :email_id, fn email_id ->
      case Database.PrefixedUUID.slug_to_uuid(email_id) do
        {:ok, _prefix, uuid} -> uuid
        _ -> email_id
      end
    end)
  end

  defp verify_token(token) when is_binary(token) do
    Token.verify(Endpoint, key_salt(), token)
  end

  defp key_salt, do: Endpoint.config(:secret_key_base)
end
