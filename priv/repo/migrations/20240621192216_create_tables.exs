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
      add :state, :string, null: false
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
      add :logo, :string
      add :state, :string, null: false
      add :website, :string, null: false
      add :display_name, :string, null: false
      add :primary_button_color, :citext, null: false
      add :secondary_button_color, :citext, null: false
      add :email_configuration_set, :string
      add :email_tracking, :boolean, default: false

      add :org_id, references(:orgs, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:apps, [:org_id], where: "deleted_at is null")

    ## Media

    create table(:media, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :mime, :string, null: false
      add :size, :integer, null: false
      add :public_url, :string

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:media, [:app_id])

    ## Auth tokens

    create table(:auth_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key, :binary, null: false
      add :key_hash, :binary, null: false
      add :scopes, {:array, :string}, null: false, default: []

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create unique_index(:auth_tokens, [:key], where: "deleted_at is null")
    create unique_index(:auth_tokens, [:key_hash], where: "deleted_at is null")
    create unique_index(:auth_tokens, [:app_id], where: "deleted_at is null")

    ## Domain

    create table(:domains, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :citext, null: false
      add :kind, :string, null: false
      add :state, :string, null: false
      add :purpose, :string, null: false
      add :verified, :boolean, null: false
      add :tags, {:array, :string}, null: false, default: []

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create unique_index(:domains, [:name], where: "verified AND deleted_at is null")
    create unique_index(:domains, [:app_id, :purpose], where: "deleted_at is null")

    create table(:domain_records, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :kind, :string, null: false
      add :name, :citext, null: false
      add :value, :string, null: false
      add :priority, :integer, null: false, default: 0
      add :verified, :boolean, null: false, default: false

      add :domain_id, references(:domains, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:domain_records, [:domain_id])
    create unique_index(:domain_records, [:domain_id, :kind, :name, :value])

    ## Email

    create table(:email_templates, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :tags, {:array, :string}, null: false, default: []

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:email_templates, [:app_id])

    create table(:email_template_locales, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :style, :string, null: false
      add :subject, :string, null: false
      add :language, :string, null: false
      add :preheader, :string, null: false
      add :html_body, :text, null: false
      add :mjml_body, :text, null: false

      add :email_template_id, references(:email_templates, type: :uuid, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:email_template_locales, [:email_template_id])
    create unique_index(:email_template_locales, [:email_template_id, :language])

    create table(:email_template_styles, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :style, :string, null: false
      add :html_body, :text, null: false
      add :mjml_body, :text, null: false

      add :email_template_locale_id,
          references(:email_template_locales, type: :uuid, on_delete: :delete_all),
          null: false

      timestamps()
    end

    create index(:email_template_styles, [:email_template_locale_id])
    create unique_index(:email_template_styles, [:email_template_locale_id, :style])

    ## Methods

    create table(:magic_link_authenticators, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :expires, :integer, null: false, default: 15
      add :sender, :citext, null: false
      add :sender_name, :string, null: false
      add :email_tracking, :boolean, null: false, default: false
      add :fingerprint_device, :boolean, null: false, default: false
      add :redirect_urls, :map, null: false, default: %{}

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :email_template_id, references(:email_templates, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:magic_link_authenticators, [:app_id])

    create table(:sms_authenticators, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :expires, :integer, null: false, default: 5

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:sms_authenticators, [:app_id])

    create table(:whatsapp_authenticators, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :expires, :integer, null: false, default: 5

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:whatsapp_authenticators, [:app_id])

    create table(:email_authenticators, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :expires, :integer, null: false, default: 15
      add :sender, :citext, null: false
      add :sender_name, :string, null: false
      add :email_tracking, :boolean, null: false, default: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :email_template_id, references(:email_templates, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:email_authenticators, [:app_id])

    create table(:totp_authenticators, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :issuer_name, :string, null: false
      add :hide_download_screen, :boolean, null: false, default: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:totp_authenticators, [:app_id])

    create table(:security_key_authenticators, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :relying_party_id, :string, null: false
      add :expected_origins, :map, null: false, default: %{}

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:security_key_authenticators, [:app_id])

    create table(:passkey_authenticators, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :relying_party_id, :string, null: false
      add :expected_origins, :map, null: false, default: %{}
      add :uplift_prompt_interval, :string, null: false
      add :require_user_verification, :boolean, null: false, default: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:passkey_authenticators, [:app_id])

    create table(:recovery_codes_authenticators, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :enabled, :boolean, null: false, default: true
      add :hide_on_enrollment, :boolean, null: false, default: false
      add :skip_on_programatic, :boolean, null: false, default: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:recovery_codes_authenticators, [:app_id])

    ## Message mapping

    create table(:email_message_mappings, primary_key: false) do
      add :external_id, :string, primary_key: true
      add :email_message_id, :uuid, null: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create index(:email_message_mappings, [:app_id])
    create unique_index(:email_message_mappings, [:email_message_id])

    ## Magic Link mapping

    create table(:magic_link_mappings, primary_key: false) do
      add :token, :binary, primary_key: true
      add :magic_link_id, :uuid, null: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create index(:magic_link_mappings, [:app_id])
    create unique_index(:magic_link_mappings, [:magic_link_id])

    ## Email Unsubscribe Link mapping

    create table(:email_unsubscribe_link_mappings, primary_key: false) do
      add :token, :binary, primary_key: true
      add :email_id, :uuid, null: false

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create index(:email_unsubscribe_link_mappings, [:app_id])
    create unique_index(:email_unsubscribe_link_mappings, [:email_id])

    ## Billing items

    create table(:billing_items, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :kind, :string, null: false
      add :name, :string, null: false
      add :period_start, :utc_datetime_usec, null: false
      add :period_end, :utc_datetime_usec, null: false
      add :amount, :integer, null: false, default: 0
      add :amount_max, :integer, null: false, default: 0
      add :base_cost, :integer, null: false, default: 0
      add :added_cost, :integer, null: false, default: 0
      add :total_cost, :integer, null: false, default: 0

      add :app_id, references(:apps, type: :uuid, on_delete: :delete_all), null: false
      add :org_id, references(:orgs, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:billing_items, [:app_id])
    create index(:billing_items, [:org_id])

    ## Activity Log

    create table(:activity_logs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :action, :string, null: false
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

      # Email
      add :domain_id, references(:domains, type: :uuid, on_delete: :nilify_all)

      timestamps(updated_at: false)
    end

    create index(:activity_logs, [:org_id])
    create index(:activity_logs, [:org_id, :action])
    create index(:activity_logs, [:user_id])
    create index(:activity_logs, [:auth_token_id])
    create index(:activity_logs, [:target_user_id])
    create index(:activity_logs, [:app_id])
    create index(:activity_logs, [:billing_customer_id])
    create index(:activity_logs, [:billing_subscription_id])
    create index(:activity_logs, [:domain_id])

    execute "create index activity_logs_happened_at_idx on activity_logs ((happened_at::date));"
  end
end
