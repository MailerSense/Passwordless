defmodule Passwordless.EmailMessageMapping do
  @moduledoc """
  An email message SES mapping.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Database.ChangesetExt
  alias Passwordless.App

  @primary_key false
  @timestamps_opts [type: :utc_datetime]
  @foreign_key_type :binary_id

  schema "email_message_mapping" do
    field :ses_id, :string, primary_key: true
    field :email_message_id, :binary_id

    belongs_to :app, App, type: :binary_id

    timestamps(updated_at: false)
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
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> unique_constraint(:email_message_id)
    |> unsafe_validate_unique(:email_message_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end
end
