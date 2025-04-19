defmodule Passwordless.Repo.TenantMigrations.CreateTables do
  use Ecto.Migration

  import Database.SoftDelete.Migration

  def change do
    execute "create extension if not exists citext", ""
    execute "create extension if not exists pg_trgm", ""

    ## Actors

    create table(:actors, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :text
      add :state, :string, null: false
      add :username, :string
      add :language, :string, null: false
      add :properties, :map, null: false, default: %{}

      timestamps()
      soft_delete_column()
    end

    create index(:actors, [:state], where: "deleted_at is null")
    create unique_index(:actors, [:username], where: "deleted_at is null")

    execute "create index actors_name_gin_trgm_idx on #{prefix()}.actors using gin (name gin_trgm_ops) where deleted_at is null;"

    execute "create index actors_username_gin_trgm_idx on #{prefix()}.actors using gin (username gin_trgm_ops) where deleted_at is null;"

    execute "create index actors_properties_gin_trgm_idx on #{prefix()}.actors using gin ((properties::text) gin_trgm_ops) where deleted_at is null;"

    ## Action Behavior

    create table(:rules, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :condition, :map, null: false, default: %{}
      add :effects, :map, null: false, default: %{}

      timestamps()
    end

    ## Action

    create table(:actions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :state, :string, null: false
      add :completed_at, :utc_datetime_usec

      add :rule_id, references(:rules, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:actions, [:name])
    create index(:actions, [:rule_id])
    create index(:actions, [:actor_id])

    ## Challenge

    create table(:challenges, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string, null: false
      add :state, :string, null: false
      add :current, :boolean, null: false, default: false

      add :action_id, references(:actions, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:challenges, [:action_id], where: "\"current\"")

    ## Emails

    create table(:emails, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :address, :citext, null: false
      add :primary, :boolean, null: false, default: false
      add :verified, :boolean, null: false, default: false
      add :opted_out_at, :utc_datetime_usec

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:emails, [:actor_id], where: "deleted_at is null")
    create unique_index(:emails, [:actor_id, :primary], where: "\"primary\"")
    create unique_index(:emails, [:actor_id, :address], where: "deleted_at is null")

    execute "create index emails_email_gin_trgm_idx on #{prefix()}.emails using gin (address gin_trgm_ops);"

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
      add :channels, {:array, :string}, null: false, default: []
      add :opted_out_at, :utc_datetime_usec

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:phones, [:actor_id], where: "deleted_at is null")
    create unique_index(:phones, [:actor_id, :primary], where: "\"primary\"")
    create unique_index(:phones, [:actor_id, :canonical], where: "deleted_at is null")

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

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:totps, [:actor_id], where: "deleted_at is null")

    ## Recovery codes

    create table(:recovery_codes, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :codes, :map, null: false, default: %{}

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create unique_index(:recovery_codes, [:actor_id], where: "deleted_at is null")

    ## Security Key Holders

    create table(:security_key_holders, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :handle, :string, null: false

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:security_key_holders, [:actor_id], where: "deleted_at is null")
    create unique_index(:security_key_holders, [:handle], where: "deleted_at is null")
    create unique_index(:security_key_holders, [:actor_id, :handle], where: "deleted_at is null")

    ## Security Keys

    create table(:security_keys, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      add :security_key_holder_id,
          references(:security_key_holders, type: :uuid, on_delete: :delete_all),
          null: false

      timestamps()
      soft_delete_column()
    end

    ## Action details

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

    create table(:magic_links, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :token, :binary, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :accepted_at, :utc_datetime_usec

      add :email_message_id, references(:email_messages, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create unique_index(:magic_links, [:email_message_id])

    ## Action events

    create table(:action_events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :event, :string, null: false
      add :metadata, :map, null: false, default: %{}
      add :user_agent, :string
      add :ip_address, :string
      add :country, :string
      add :city, :string

      add :action_id, references(:actions, type: :uuid, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create index(:action_events, [:action_id])
  end
end
