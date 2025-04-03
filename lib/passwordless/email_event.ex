defmodule Passwordless.EmailEvent do
  @moduledoc """
  Email events like sends, opens and bounces etc.
  """

  use Passwordless.Schema, prefix: "eevent"

  alias Database.ChangesetExt
  alias Passwordless.EmailMessage

  @kinds ~w(
    open
    click
    bounce
    complaint
    delivery
    reject
    delay
    subscription
    rendering_failure
    suspend
  )a
  @bounce_types ~w(
    transient
    permanent
    undetermined
    unknown
  )a
  @bounce_subtypes ~w(
    general
    no_email
    suppressed
    on_account_suppression_list
    undetermined
    mailbox_full
    message_too_large
    content_rejected
    attachment_rejected
    unknown
  )a
  @complaint_types ~w(
    abuse
    auth_failure
    fraud
    not_spam
    other
    virus
    unknown
  )a
  @complaint_subtypes ~w(
    on_account_suppression_list
    unknown
  )a
  @reject_reasons ~w(
    bad_content
    unknown
  )a
  @delay_reasons ~w(
    internal_failure
    general
    mailbox_full
    spam_detected
    recipient_server_error
    ip_failure
    transient_communication_failure
    byoip_host_name_lookup_unavailable
    undetermined
    sending_deferral
    unknown
  )a

  @derive {
    Flop.Schema,
    sortable: [:id], filterable: [:id]
  }
  schema "email_events" do
    # Kind
    field :kind, Ecto.Enum, values: @kinds

    # Timestamp
    field :happened_at, :utc_datetime_usec

    # Feedback
    field :feedback_id, :string

    # Open
    field :open_ip_address, :string
    field :open_user_agent, :string

    # Click
    field :click_url, :string
    field :click_url_tags, {:array, :string}
    field :click_ip_address, :string
    field :click_user_agent, :string

    # Bounce
    field :bounce_type, Ecto.Enum, values: @bounce_types
    field :bounce_subtype, Ecto.Enum, values: @bounce_subtypes

    embeds_many :bounced_recipients, BouncedRecipient, on_replace: :delete do
      @derive Jason.Encoder

      field :name, :string
      field :email, :string
      field :status, :string
      field :action, :string
      field :diagnostic_code, :string
    end

    # Complaint
    field :complaint_type, Ecto.Enum, values: @complaint_types
    field :complaint_subtype, Ecto.Enum, values: @complaint_subtypes
    field :complaint_user_agent, :string

    embeds_many :complained_recipients, ComplainedRecipient, on_replace: :delete do
      @derive Jason.Encoder

      field :name, :string
      field :email, :string
    end

    # Delivery
    field :delivery_smtp_response, :string
    field :delivery_reporting_mta, :string
    field :delivery_processing_time_millis, :integer

    # Reject
    field :reject_reason, Ecto.Enum, values: @reject_reasons

    # Delay
    field :delay_reason, Ecto.Enum, values: @delay_reasons
    field :delay_reporting_mta, :string
    field :delay_expiration_time, :utc_datetime_usec

    embeds_many :delayed_recipients, DelayedRecipient, on_replace: :delete do
      @derive Jason.Encoder

      field :name, :string
      field :email, :string
      field :status, :string
      field :diagnostic_code, :string
    end

    # Subscription
    field :subscription_source, :string
    field :subscription_contact_list, :string

    # Rendering Failure
    field :rendering_error_message, :string
    field :rendering_teplate_name, :string

    # Suspend
    field :suspend_reason, :string

    belongs_to :email_message, EmailMessage

    timestamps(updated_at: false)
  end

  @fields ~w(
    kind
    happened_at
    feedback_id
    open_ip_address
    open_user_agent
    click_url
    click_url_tags
    click_ip_address
    click_user_agent
    bounce_type
    bounce_subtype
    complaint_type
    complaint_subtype
    complaint_user_agent
    delivery_smtp_response
    delivery_reporting_mta
    delivery_processing_time_millis
    reject_reason
    delay_reason
    delay_reporting_mta
    delay_expiration_time
    subscription_source
    subscription_contact_list
    rendering_error_message
    rendering_teplate_name
    suspend_reason
  )a

  @required_fields ~w(kind)a

  @doc """
  A changeset to create a new email event.
  """
  def changeset(%__MODULE__{} = event, attrs \\ %{}) do
    event
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> cast_embed(:bounced_recipients, with: &bouced_recipient_changeset/2)
    |> cast_embed(:complained_recipients, with: &complained_recipient_changeset/2)
    |> cast_embed(:delayed_recipients, with: &delayed_recipient_changeset/2)
  end

  # Private

  @bouced_recipient_fields ~w(name email status action diagnostic_code)a

  defp bouced_recipient_changeset(%__MODULE__.BouncedRecipient{} = recipient, attrs) do
    recipient
    |> cast(attrs, @bouced_recipient_fields)
    |> ChangesetExt.ensure_trimmed(@bouced_recipient_fields)
  end

  @complained_recipient_fields ~w(name email)a

  defp complained_recipient_changeset(%__MODULE__.ComplainedRecipient{} = recipient, attrs) do
    recipient
    |> cast(attrs, @complained_recipient_fields)
    |> ChangesetExt.ensure_trimmed(@complained_recipient_fields)
  end

  @delayed_recipient_fields ~w(name email status diagnostic_code)a

  defp delayed_recipient_changeset(%__MODULE__.DelayedRecipient{} = recipient, attrs) do
    recipient
    |> cast(attrs, @delayed_recipient_fields)
    |> ChangesetExt.ensure_trimmed(@delayed_recipient_fields)
  end
end
