defmodule Passwordless.Repo.Migrations.CreateTables do
  use Ecto.Migration

  import Database.SoftDelete.Migration

  def change do
    execute "create extension if not exists citext", ""
    execute "create extension if not exists pg_trgm", ""

    ## Accounts

    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :email, :citext, null: false
      add :state, :string, null: false
      add :confirmed_at, :utc_datetime_usec
      add :password_hash, :string

      timestamps()
      soft_delete_column()
    end

    create unique_index(:users, [:email], where: "deleted_at is null")

    create table(:user_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :email, :citext
      add :token, :binary, null: false
      add :context, :string, null: false

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:user_tokens, [:user_id])
    create index(:user_tokens, [:user_id, :context, :token])
    create index(:user_tokens, [:context, :token])
    create unique_index(:user_tokens, [:token])

    create table(:user_credentials, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :subject, :string
      add :provider, :string

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:user_credentials, [:user_id])
    create unique_index(:user_credentials, [:user_id, :provider])
    create unique_index(:user_credentials, [:subject, :provider])

    create table(:user_totps, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :secret, :binary, null: false
      add :backup_codes, :map, null: false, default: %{}

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:user_totps, [:user_id])

    ## Organizations

    create table(:orgs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :email, :citext, null: false
      add :tags, {:array, :string}, null: false, default: []

      timestamps()
      soft_delete_column()
    end

    create unique_index(:orgs, [:email], where: "deleted_at is null")

    create table(:org_memberships, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :role, :string, null: false

      add :org_id, references(:orgs, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:org_memberships, [:org_id, :user_id])

    create table(:org_invitations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :email, :citext

      add :org_id, references(:orgs, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end

    create index(:org_invitations, [:user_id])
    create unique_index(:org_invitations, [:org_id, :email])

    ## API Keys

    create table(:auth_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key, :binary, null: false
      add :name, :string, null: false
      add :state, :string, null: false
      add :scopes, {:array, :string}, null: false, default: []
      add :signature, :string, null: false

      add :org_id, references(:orgs, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:auth_tokens, [:org_id])
    create unique_index(:auth_tokens, [:key], where: "deleted_at is null")

    ## Billing

    create table(:billing_customers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :provider, :string, null: false
      add :provider_id, :string, null: false

      add :org_id, references(:orgs, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create unique_index(:billing_customers, [:org_id], where: "deleted_at is null")
    create unique_index(:billing_customers, [:provider_id], where: "deleted_at is null")

    create table(:billing_subscriptions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :state, :string, null: false
      add :provider_id, :string, null: false

      add :created_at, :utc_datetime_usec
      add :ended_at, :utc_datetime_usec
      add :cancel_at, :utc_datetime_usec
      add :canceled_at, :utc_datetime_usec
      add :current_period_start, :utc_datetime_usec
      add :current_period_end, :utc_datetime_usec
      add :trial_start, :utc_datetime_usec
      add :trial_end, :utc_datetime_usec

      add :customer_id, references(:billing_customers, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps()
      soft_delete_column()
    end

    create unique_index(:billing_subscriptions, [:customer_id], where: "deleted_at is null")
    create unique_index(:billing_subscriptions, [:provider_id], where: "deleted_at is null")

    create table(:billing_subscription_items, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :quantity, :integer, null: false, default: 1

      add :created_at, :utc_datetime_usec
      add :provider_id, :string, null: false
      add :provider_price_id, :string, null: false
      add :provider_product_id, :string, null: false
      add :recurring_interval, :string
      add :recurring_usage_type, :string

      add :subscription_id,
          references(:billing_subscriptions, type: :uuid, on_delete: :delete_all),
          null: false

      timestamps()
      soft_delete_column()
    end

    create index(:billing_subscription_items, [:subscription_id])
    create unique_index(:billing_subscription_items, [:provider_id], where: "deleted_at is null")

    ## Apps

    create table(:apps, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :website, :string, null: false
      add :display_name, :string, null: false
      add :primary_button_color, :string, null: false
      add :secondary_button_color, :string, null: false

      add :org_id, references(:orgs, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:apps, [:org_id], where: "deleted_at is null")

    ## Actors

    create table(:actors, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :state, :string, null: false
      add :language, :string, null: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:actors, [:app_id], where: "deleted_at is null")
    create index(:actors, [:state], where: "deleted_at is null")

    execute "create index actors_name_gin_trgm_idx on actors using gin (name gin_trgm_ops);"

    ## Emails

    create table(:emails, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :address, :citext, null: false
      add :primary, :boolean, null: false, default: false
      add :verified, :boolean, null: false, default: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:emails, [:actor_id], where: "deleted_at is null")
    create unique_index(:emails, [:app_id, :address], where: "deleted_at is null")
    create unique_index(:emails, [:app_id, :actor_id, :primary], where: "\"primary\"")
    create unique_index(:emails, [:app_id, :actor_id, :address], where: "deleted_at is null")

    execute "create index emails_email_gin_trgm_idx on emails using gin (address gin_trgm_ops);"

    ## Phones

    create table(:phones, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :address, :citext, null: false
      add :primary, :boolean, null: false, default: false
      add :verified, :boolean, null: false, default: false
      add :channels, {:array, :string}, null: false, default: []

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:phones, [:actor_id], where: "deleted_at is null")
    create unique_index(:phones, [:app_id, :address], where: "deleted_at is null")
    create unique_index(:phones, [:app_id, :actor_id, :primary], where: "\"primary\"")
    create unique_index(:phones, [:app_id, :actor_id, :address], where: "deleted_at is null")

    execute "create index phones_email_gin_trgm_idx on phones using gin (address gin_trgm_ops);"

    ## TOTPS

    create table(:totps, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :secret, :binary, null: false
      add :backup_codes, :map, null: false, default: %{}

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:totps, [:actor_id], where: "deleted_at is null")
    create unique_index(:totps, [:app_id, :secret], where: "deleted_at is null")
    create unique_index(:totps, [:app_id, :actor_id, :secret], where: "deleted_at is null")

    ## Security Key Holders

    create table(:security_key_holders, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :handle, :string, null: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:security_key_holders, [:actor_id], where: "deleted_at is null")
    create unique_index(:security_key_holders, [:app_id, :handle], where: "deleted_at is null")

    create unique_index(:security_key_holders, [:app_id, :actor_id, :handle],
             where: "deleted_at is null"
           )

    ## Security Keys

    create table(:security_keys, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      add :security_key_holder_id,
          references(:security_key_holders, type: :uuid, on_delete: :delete_all),
          null: false

      timestamps()
      soft_delete_column()
    end

    ## Action

    create table(:actions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :method, :string, null: false
      add :outcome, :string, null: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:actions, [:app_id])
    create index(:actions, [:actor_id])
    create index(:actions, [:outcome])

    ## Challenge

    create table(:challenges, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :state, :string, null: false
      add :method, :string, null: false
      add :context, :string, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :attempts, :integer, null: false, default: 0
      add :token, :binary, null: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false
      add :action_id, references(:actions, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:challenges, [:actor_id], where: "deleted_at is null")
    create unique_index(:challenges, [:app_id, :token], where: "deleted_at is null")
    create unique_index(:challenges, [:app_id, :actor_id, :token], where: "deleted_at is null")

    create unique_index(:challenges, [:app_id, :actor_id, :action_id],
             where: "deleted_at is null"
           )

    ## Events

    create table(:events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :state, :string, null: false
      add :details, :string
      add :ip_address, :string
      add :country, :string
      add :city, :string

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :actor_id, references(:actors, type: :uuid, on_delete: :nilify_all)
      add :action_id, references(:actions, type: :uuid, on_delete: :nilify_all)
      add :challenge_id, references(:challenges, type: :uuid, on_delete: :nilify_all)

      timestamps(updated_at: false)
    end

    create index(:events, [:app_id])
    create index(:events, [:actor_id])
    create index(:events, [:action_id])
    create index(:events, [:challenge_id])

    ## Domain

    create table(:domains, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :citext, null: false
      add :kind, :string, null: false
      add :state, :string, null: false
      add :verified, :boolean, null: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create unique_index(:domains, [:app_id], where: "deleted_at is null")
    create unique_index(:domains, [:name], where: "verified AND deleted_at is null")

    create table(:domain_records, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :kind, :string, null: false
      add :name, :citext, null: false
      add :value, :string, null: false
      add :verified, :boolean, null: false, default: false

      add :domain_id, references(:domains, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:domain_records, [:domain_id])
    create unique_index(:domain_records, [:domain_id, :kind, :name, :value])

    ## Methods

    create table(:magic_link_methods, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :expires, :integer, null: false, default: 15
      add :sender, :string, null: false
      add :sender_name, :string, null: false
      add :email_tracking, :boolean, null: false, default: false
      add :fingerprint_device, :boolean, null: false, default: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :domain_id, references(:domains, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:magic_link_methods, [:app_id])
    create unique_index(:magic_link_methods, [:domain_id])

    create table(:sms_methods, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :expires, :integer, null: false, default: 5

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:sms_methods, [:app_id])

    create table(:email_methods, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :expires, :integer, null: false, default: 15
      add :sender, :string, null: false
      add :sender_name, :string, null: false
      add :email_tracking, :boolean, null: false, default: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :domain_id, references(:domains, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:email_methods, [:app_id])
    create unique_index(:email_methods, [:domain_id])

    create table(:authenticator_methods, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :issuer_name, :string, null: false
      add :hide_download_screen, :boolean, null: false, default: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:authenticator_methods, [:app_id])

    create table(:security_key_methods, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :relying_party_id, :string, null: false
      add :expected_origins, :map, null: false, default: %{}

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:security_key_methods, [:app_id])

    create table(:passkey_methods, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :relying_party_id, :string, null: false
      add :expected_origins, :map, null: false, default: %{}
      add :uplift_prompt_interval, :string, null: false
      add :require_user_verification, :boolean, null: false, default: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:passkey_methods, [:app_id])

    ## Activity Log

    create table(:activity_logs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :action, :string, null: false
      add :domain, :string, null: false
      add :metadata, :map
      add :happened_at, :utc_datetime_usec, null: false

      # Org
      add :org_id, references(:orgs, type: :uuid, on_delete: :nilify_all)
      add :user_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :auth_token_id, references(:auth_tokens, type: :uuid, on_delete: :nilify_all)
      add :target_user_id, references(:users, type: :uuid, on_delete: :nilify_all)

      # Apps
      add :app_id, references(:apps, type: :uuid, on_delete: :nilify_all)

      # Billing
      add :billing_customer_id,
          references(:billing_customers, type: :uuid, on_delete: :nilify_all)

      add :billing_subscription_id,
          references(:billing_subscriptions, type: :uuid, on_delete: :nilify_all)

      timestamps(updated_at: false)
    end

    create index(:activity_logs, [:org_id])
    create index(:activity_logs, [:org_id, :action])
    create index(:activity_logs, [:org_id, :domain])
    create index(:activity_logs, [:user_id])
    create index(:activity_logs, [:auth_token_id])
    create index(:activity_logs, [:target_user_id])
    create index(:activity_logs, [:app_id])
    create index(:activity_logs, [:billing_customer_id])
    create index(:activity_logs, [:billing_subscription_id])

    execute "create index activity_logs_happened_at_idx on activity_logs ((happened_at::date));"
  end
end
