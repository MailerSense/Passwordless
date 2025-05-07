defmodule Passwordless.EmailMessage do
  @moduledoc """
  An email message.
  """

  use Passwordless.Schema, prefix: "emmsg"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Challenge
  alias Passwordless.Domain
  alias Passwordless.Email
  alias Passwordless.EmailEvent
  alias Passwordless.EmailTemplateLocale
  alias Passwordless.MagicLink
  alias Passwordless.OTP
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @states ~w(
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
    Jason.Encoder,
    only: [
      :id,
      :state,
      :sender,
      :sender_name,
      :recipient,
      :recipient_name,
      :reply_to,
      :reply_to_name,
      :subject,
      :metadata,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id], custom_fields: []
  }
  schema "email_messages" do
    field :state, Ecto.Enum, values: @states, default: :submitted
    field :sender, :string
    field :sender_name, :string
    field :recipient, :string
    field :recipient_name, :string
    field :reply_to, :string
    field :reply_to_name, :string
    field :subject, :string
    field :text_content, :string
    field :html_content, :string
    field :current, :boolean, default: false

    embeds_one :metadata, Metadata, on_replace: :delete do
      @derive Jason.Encoder

      field :source, :string
      field :source_arn, :string
      field :sending_account_id, :string
      field :headers_truncated, :boolean

      embeds_many :tags, Tag, on_replace: :delete do
        @derive Jason.Encoder

        field :name, :string
        field :value, {:array, :string}
      end

      embeds_many :headers, Header, on_replace: :delete do
        @derive Jason.Encoder

        field :name, :string
        field :value, :string
      end
    end

    has_one :otp, OTP
    has_one :magic_link, MagicLink

    has_many :email_events, EmailEvent, preload_order: [asc: :inserted_at]

    belongs_to :email, Email
    belongs_to :domain, Domain
    belongs_to :challenge, Challenge
    belongs_to :email_template_locale, EmailTemplateLocale

    timestamps()
  end

  def states, do: @states
  def failed_states, do: ~w(rejected bounced supressed complaint_received)a

  @fields ~w(
    state
    sender
    sender_name
    recipient
    recipient_name
    reply_to
    reply_to_name
    subject
    text_content
    html_content
    current
    email_id
    domain_id
    challenge_id
    email_template_locale_id
  )a

  @required_fields ~w(
    state
    sender
    recipient
    subject
    text_content
    html_content
    current
    email_id
    domain_id
    challenge_id
    email_template_locale_id
  )a

  @doc """
  A message changeset.
  """
  def changeset(%__MODULE__{} = email_message, attrs \\ %{}, opts \\ []) do
    email_message
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> ChangesetExt.validate_email(:sender)
    |> ChangesetExt.validate_email(:reply_to)
    |> ChangesetExt.validate_email(:recipient)
    |> validate_text(:sender_name)
    |> validate_text(:reply_to_name)
    |> validate_text(:recipient_name)
    |> validate_subject()
    |> validate_content()
    |> assoc_constraint(:email)
    |> assoc_constraint(:domain)
    |> assoc_constraint(:challenge)
    |> assoc_constraint(:email_template_locale)
    |> unique_constraint([:action_id, :current], error_key: :current)
    |> unsafe_validate_unique([:action_id, :current], Passwordless.Repo,
      query: from(e in __MODULE__, where: e.current),
      prefix: Keyword.get(opts, :prefix),
      error_key: :current
    )
    |> cast_embed(:metadata, with: &metadata_changeset/2)
  end

  @external_fields ~w(
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

  defp validate_content(changeset) do
    changeset
    |> validate_required([:text_content, :html_content])
    |> update_change(:text_content, &HtmlSanitizeEx.strip_tags/1)

    # |> update_change(:html_content, &HtmlSanitizeEx.html5/1)
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
    |> cast_embed(:tags, with: &metadata_tag_changeset/2)
    |> cast_embed(:headers, with: &metadata_header_changeset/2)
  end

  defp metadata_tag_changeset(%__MODULE__.Metadata.Tag{} = tag, attrs) do
    tag
    |> cast(attrs, [:name, :value])
    |> ChangesetExt.ensure_trimmed(:name)
    |> ChangesetExt.clean_array(:value)
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
