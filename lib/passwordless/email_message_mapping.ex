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
    field :ses_id, :string, primary_key: true
    field :email_message_id, :binary_id

    belongs_to :app, App

    timestamps(updated_at: false)
  end

  def get_by_ses_id(ses_id) when is_binary(ses_id) do
    from(
      m in __MODULE__,
      where: m.ses_id == ^ses_id,
      left_join: a in assoc(m, :app),
      select: {m, a}
    )
  end

  @fields ~w(
    ses_id
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
    |> ChangesetExt.ensure_trimmed(:ses_id)
    |> unique_constraint(:email_message_id)
    |> unsafe_validate_unique(:email_message_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end
end
