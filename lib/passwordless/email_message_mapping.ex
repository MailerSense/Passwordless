defmodule Passwordless.EmailMessageMapping do
  @moduledoc """
  An email message SES mapping.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.App

  @primary_key false
  @timestamps_opts [type: :utc_datetime]
  @foreign_key_type Database.PrefixedUUID

  schema "email_message_mapping" do
    field :external_id, :string, primary_key: true
    field :email_message_id, :binary_id

    belongs_to :app, App

    timestamps(updated_at: false)
  end

  def get_by_external_id(external_id) when is_binary(external_id) do
    from(
      m in __MODULE__,
      where: m.external_id == ^external_id,
      left_join: a in assoc(m, :app),
      select: {m, a}
    )
  end

  @fields ~w(
    external_id
    email_message_id
    app_id
  )a
  @required_fields @fields

  @doc """
  A message mapping changeset.
  """
  def changeset(%__MODULE__{} = message_mapping, attrs \\ %{}) do
    message_mapping
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_external_id()
    |> decode_email_message_id()
    |> unique_constraint(:email_message_id)
    |> unsafe_validate_unique(:email_message_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end

  # Private

  defp validate_external_id(%Ecto.Changeset{} = changeset) do
    ChangesetExt.ensure_trimmed(changeset, :external_id)
  end

  defp decode_email_message_id(changeset) do
    update_change(changeset, :email_message_id, fn email_id ->
      case Database.PrefixedUUID.slug_to_uuid(email_id) do
        {:ok, _prefix, uuid} -> uuid
        _ -> email_id
      end
    end)
  end
end
