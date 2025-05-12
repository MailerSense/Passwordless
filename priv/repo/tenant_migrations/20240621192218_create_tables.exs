defmodule Passwordless.Repo.TenantMigrations.CreateTables do
  use Ecto.Migration

  import Database.SoftDelete.Migration
  import SqlFmt.Helpers

  def change do
    execute ~SQL"CREATE extension IF NOT EXISTS citext", ""
    execute ~SQL"CREATE extension IF NOT EXISTS pg_trgm", ""

    ## Users

    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :data, :binary, null: false
      add :language, :string

      timestamps()
      soft_delete_column()
    end

    ## Action Templates

    create table(:action_templates, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :alias, :string, null: false
      add :rules, :map

      timestamps()
      soft_delete_column()
    end

    create unique_index(:action_templates, [:alias], where: "deleted_at is null")

    ## Action

    create table(:actions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :data, :binary
      add :state, :string, null: false
      add :completed_at, :utc_datetime_usec

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      add :action_template_id, references(:action_templates, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:actions, [:user_id])
    create index(:actions, [:action_template_id])

    # Action Statistics

    create table(:action_statistics, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :attempts, :integer, null: false, default: 0
      add :allowed_attempts, :integer, null: false, default: 0
      add :timed_out_attempts, :integer, null: false, default: 0
      add :blocked_attempts, :integer, null: false, default: 0

      add :action_template_id, references(:action_templates, type: :uuid, on_delete: :delete_all),
        null: false
    end

    create unique_index(:action_statistics, :action_template_id)

    ## Challenge

    create table(:challenges, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :kind, :string, null: false
      add :state, :string, null: false
      add :current, :boolean, null: false, default: false
      add :options, :map

      add :action_id, references(:actions, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:challenges, [:action_id], where: "\"current\"")

    ## Identifiers

    create table(:identifiers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :value, :citext, null: false
      add :primary, :boolean, null: false, default: false

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:identifiers, [:user_id], where: "deleted_at is null")
    create unique_index(:identifiers, [:value], where: "deleted_at is null")

    execute "create index identifiers_value_gin_trgm_idx on #{prefix()}.identifiers using gin (value gin_trgm_ops);"

    ## Emails

    create table(:emails, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :address, :citext, null: false
      add :primary, :boolean, null: false, default: false
      add :verified, :boolean, null: false, default: false
      add :opted_out_at, :utc_datetime_usec
      add :authenticators, {:array, :string}, null: false, default: []

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:emails, [:user_id], where: "deleted_at is null")
    create unique_index(:emails, [:address], where: "deleted_at is null")
    create unique_index(:emails, [:user_id, :primary], where: "\"primary\"")

    execute "create index emails_address_gin_trgm_idx on #{prefix()}.emails using gin (address gin_trgm_ops);"

    ## Email Opt Outs

    create table(:email_opt_outs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :email, :citext, null: false
      add :reason, :string, null: false

      timestamps()
    end

    create unique_index(:email_opt_outs, [:email])

    ## Email messages

    create table(:email_messages, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :state, :string, null: false
      add :sender, :citext, null: false
      add :sender_name, :string
      add :recipient, :citext, null: false
      add :recipient_name, :string
      add :reply_to, :citext, null: false
      add :reply_to_name, :string
      add :subject, :text, null: false
      add :text_content, :text, null: false
      add :html_content, :text, null: false
      add :current, :boolean, null: false, default: false
      add :metadata, :map

      add :email_id, references(:emails, type: :uuid, on_delete: :delete_all), null: false

      add :domain_id, references(:domains, type: :uuid, on_delete: :delete_all, prefix: "public"),
        null: false

      add :challenge_id, references(:challenges, type: :uuid, on_delete: :delete_all), null: false

      add :email_template_locale_id,
          references(:email_template_locales,
            type: :uuid,
            on_delete: :delete_all,
            prefix: "public"
          ),
          null: false

      timestamps()
    end

    create index(:email_messages, [:email_id])
    create index(:email_messages, [:domain_id])
    create index(:email_messages, [:email_template_locale_id])
    create unique_index(:email_messages, [:challenge_id], where: "\"current\"")

    ## Email events

    create table(:email_events, primary_key: false) do
      add :id, :uuid, primary_key: true

      # Kind
      add :kind, :string, null: false

      # Timestamp
      add :happened_at, :utc_datetime_usec, null: false

      # Open
      add :open_ip_address, :string
      add :open_user_agent, :string

      # Click
      add :click_url, :string
      add :click_url_tags, {:array, :string}
      add :click_ip_address, :string
      add :click_user_agent, :string

      # Bounce
      add :bounce_type, :string
      add :bounce_subtype, :string
      add :bounced_recipients, :map

      # Complaint
      add :complaint_type, :string
      add :complaint_subtype, :string
      add :complaint_user_agent, :string
      add :complained_recipients, :map

      # Delivery
      add :delivery_smtp_response, :string
      add :delivery_reporting_mta, :string
      add :delivery_processing_time_millis, :integer

      # Reject
      add :reject_reason, :string

      # Delay
      add :delay_reason, :string
      add :delay_reporting_mta, :string
      add :delay_expiration_time, :utc_datetime_usec
      add :delayed_recipients, :map

      # Subscription
      add :subscription_source, :string
      add :subscription_contact_list, :string

      # Rendering failure
      add :rendering_error_message, :string
      add :rendering_teplate_name, :string

      # Suspend
      add :suspend_reason, :string

      add :email_message_id, references(:email_messages, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps(updated_at: false)
    end

    create index(:email_events, [:email_message_id])

    ## Phones

    create table(:phones, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :number, :citext, null: false
      add :region, :string, null: false
      add :canonical, :citext, null: false
      add :primary, :boolean, null: false, default: false
      add :verified, :boolean, null: false, default: false
      add :opted_out_at, :utc_datetime_usec
      add :authenticators, {:array, :string}, null: false, default: []

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:phones, [:user_id], where: "deleted_at is null")
    create unique_index(:phones, [:canonical], where: "deleted_at is null")
    create unique_index(:phones, [:user_id, :primary], where: "\"primary\"")

    execute "create index phones_canonical_gin_trgm_idx on #{prefix()}.phones using gin (canonical gin_trgm_ops);"

    ## Phone messages

    create table(:phone_messages, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :recipient, :citext, null: false
      add :recipient_name, :string
      add :text_content, :text, null: false

      add :phone_id, references(:phones, type: :uuid, on_delete: :delete_all), null: false
      add :challenge_id, references(:challenges, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:phone_messages, [:phone_id])
    create index(:phone_messages, [:challenge_id])

    ## TOTPS

    create table(:totps, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :secret, :binary, null: false

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:totps, [:user_id], where: "deleted_at is null")

    ## Recovery codes

    create table(:recovery_codes, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :codes, :map, null: false, default: %{}

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create unique_index(:recovery_codes, [:user_id], where: "deleted_at is null")

    ## Security Key Holders

    create table(:security_key_holders, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :handle, :string, null: false

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:security_key_holders, [:user_id], where: "deleted_at is null")
    create unique_index(:security_key_holders, [:handle], where: "deleted_at is null")
    create unique_index(:security_key_holders, [:user_id, :handle], where: "deleted_at is null")

    ## Security Keys

    create table(:security_keys, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      add :security_key_holder_id,
          references(:security_key_holders, type: :uuid, on_delete: :delete_all),
          null: false

      timestamps()
      soft_delete_column()
    end

    ## Enrollments

    create table(:enrollments, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :state, :string, null: false

      add :totp_id, references(:totps, type: :uuid, on_delete: :nilify_all)
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    ## OTPs

    create table(:otps, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :code, :binary, null: false
      add :attempts, :integer, null: false, default: 0
      add :expires_at, :utc_datetime_usec, null: false
      add :accepted_at, :utc_datetime_usec

      add :email_message_id, references(:email_messages, type: :uuid, on_delete: :nilify_all)
      add :phone_message_id, references(:phone_messages, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:otps, [:email_message_id])
    create unique_index(:otps, [:phone_message_id])

    ## Magic links

    create table(:magic_links, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key, :binary, null: false
      add :key_hash, :binary, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :accepted_at, :utc_datetime_usec

      add :email_message_id, references(:email_messages, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create unique_index(:magic_links, [:email_message_id])

    ## Events

    create table(:events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :event, :string, null: false
      add :metadata, :map, null: false, default: %{}
      add :ip_address, :inet
      add :user_agent, :text
      add :browser, :string
      add :browser_version, :string
      add :operating_system, :string
      add :operating_system_version, :string
      add :device_type, :string
      add :language, :string
      add :city, :string
      add :region, :string
      add :country, :char, size: 2
      add :latitude, :float
      add :longitude, :float
      add :timezone, :string

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :action_id, references(:actions, type: :uuid, on_delete: :nilify_all)
      add :enrollment_id, references(:enrollments, type: :uuid, on_delete: :nilify_all)

      timestamps(updated_at: false)
    end

    create index(:events, [:user_id])
    create index(:events, [:action_id])
    create index(:events, [:enrollment_id])
  end
end
