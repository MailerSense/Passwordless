defmodule Passwordless.EmailMessage do
  @moduledoc """
  An email message.
  """

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Email
  alias Passwordless.EmailTemplate
  alias Passwordless.Event
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @states ~w(
    created
    submitted
    sent
    not_sent
    delivered
    rejected
    opened
    clicked
    bounced
    supressed
    complaint_received
  )a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: []
  }
  schema "email_messages" do
    field :state, Ecto.Enum, values: @states, default: :created
    field :sender, :string
    field :sender_name, :string
    field :recipient, :string
    field :recipient_name, :string
    field :reply_to, :string
    field :reply_to_name, :string
    field :subject, :string
    field :preheader, :string
    field :external_id, :string
    field :text_content, :string
    field :html_content, :string

    embeds_one :metadata, Metadata, on_replace: :delete do
      field :source, :string
      field :source_arn, :string
      field :sending_account_id, :string
      field :headers_truncated, :boolean

      embeds_many :tags, Tag, on_replace: :delete do
        field :name, :string
        field :value, {:array, :string}
      end

      embeds_many :headers, Header, on_replace: :delete do
        field :name, :string
        field :value, :string
      end
    end

    belongs_to :event, Event, type: :binary_id
    belongs_to :email, Email, type: :binary_id
    belongs_to :email_template, EmailTemplate, type: :binary_id

    timestamps()
  end

  def states, do: @states
  def failed_states, do: ~w(rejected bounced supressed complaint_received)a

  @doc """
  Get the message with the given external ID.
  """
  def get_by_external_id(query \\ __MODULE__, external_id) when is_binary(external_id) do
    from q in query, where: q.external_id == ^external_id
  end

  @fields ~w(
    state
    sender
    sender_name
    recipient
    recipient_name
    reply_to
    reply_to_name
    subject
    preheader
    external_id
    text_content
    html_content
    event_id
    email_id
    email_template_id
  )a

  @required_fields ~w(
    state
    sender
    recipient
    subject
    text_content
    html_content
    event_id
    email_id
    email_template_id
  )a

  @doc """
  A message changeset.
  """
  def changeset(%__MODULE__{} = message, attrs \\ %{}) do
    message
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> ChangesetExt.validate_email_format(:sender)
    |> ChangesetExt.validate_email_format(:reply_to)
    |> ChangesetExt.validate_email_format(:recipient)
    |> validate_text(:sender_name)
    |> validate_text(:reply_to_name)
    |> validate_text(:recipient_name)
    |> validate_subject()
    |> validate_preheader()
    |> validate_content()
    |> validate_external_id()
    |> assoc_constraint(:event)
    |> assoc_constraint(:email)
    |> assoc_constraint(:email_template)
    |> cast_embed(:metadata, with: &metadata_changeset/2)
  end

  @external_fields ~w(
    external_id
    sender
    sender_name
    recipient
    recipient_name
  )a

  @doc """
  An external message changeset.
  """
  def external_changeset(%__MODULE__{} = message, attrs \\ %{}) do
    message
    |> cast(attrs, @external_fields)
    |> ChangesetExt.validate_email_format(:sender)
    |> ChangesetExt.validate_email_format(:recipient)
    |> validate_text(:sender_name)
    |> validate_text(:recipient_name)
    |> validate_required([:external_id])
    |> validate_external_id()
  end

  def sign_token(%__MODULE__{id: id}) when is_binary(id) do
    Token.sign(Endpoint, token_salt(), id)
  end

  @doc """
  Get the message by signed token.
  """
  def get_by_token(token_signed) when is_binary(token_signed) do
    with {:ok, token} <- verify_token(token_signed) do
      {:ok, from(m in __MODULE__, where: m.id == ^token)}
    end
  end

  # Private

  defp validate_text(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> validate_length(field, min: 1, max: 160)
  end

  defp validate_subject(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:subject)
    |> validate_length(:subject, min: 1, max: 640)
  end

  defp validate_preheader(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:preheader)
    |> validate_length(:preheader, min: 1, max: 640)
  end

  defp validate_content(changeset) do
    changeset
    |> validate_required([:text_content, :html_content])
    |> update_change(:text_content, &HtmlSanitizeEx.strip_tags/1)
    |> update_change(:html_content, &HtmlSanitizeEx.html5/1)
  end

  defp validate_external_id(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:external_id)
    |> unique_constraint(:external_id)
  end

  @metadata_fields ~w(
    source
    source_arn
    sending_account_id
    headers_truncated
  )a

  defp metadata_changeset(%__MODULE__.Metadata{} = metadata, attrs) do
    metadata
    |> cast(attrs, @metadata_fields)
    |> ChangesetExt.ensure_trimmed(:source)
    |> ChangesetExt.ensure_trimmed(:source_arn)
    |> ChangesetExt.ensure_trimmed(:sending_account_id)
    |> cast_assoc(:tags, with: &metadata_tag_changeset/2)
    |> cast_assoc(:headers, with: &metadata_header_changeset/2)
  end

  defp metadata_tag_changeset(%__MODULE__.Metadata.Tag{} = tag, attrs) do
    tag
    |> cast(attrs, [:name, :value])
    |> ChangesetExt.ensure_trimmed(:name)
    |> ChangesetExt.ensure_trimmed(:value)
  end

  defp metadata_header_changeset(%__MODULE__.Metadata.Header{} = header, attrs) do
    header
    |> cast(attrs, [:name, :value])
    |> ChangesetExt.ensure_trimmed(:name)
    |> ChangesetExt.ensure_trimmed(:value)
  end

  defp verify_token(token) when is_binary(token) do
    Token.verify(Endpoint, token_salt(), token)
  end

  defp token_salt, do: Endpoint.config(:secret_key_base)
end
