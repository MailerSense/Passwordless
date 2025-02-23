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
      add :slug, :citext, null: false
      add :name, :string, null: false
      add :email, :citext, null: false
      add :tags, {:array, :string}, null: false, default: []

      timestamps()
      soft_delete_column()
    end

    create unique_index(:orgs, [:slug], where: "deleted_at is null")
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

    ## Projects

    create table(:projects, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :slug, :citext, null: false
      add :name, :string, null: false
      add :description, :string

      add :org_id, references(:orgs, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create unique_index(:projects, [:org_id, :slug], where: "deleted_at is null")

    ## Actors

    create table(:actors, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :email, :citext, null: false
      add :phone, :citext
      add :state, :string, null: false
      add :country, :string, null: false
      add :first_name, :string
      add :last_name, :string
      add :user_id, :string

      add :project_id, references(:projects, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:actors, [:project_id], where: "deleted_at is null")
    create index(:actors, [:state], where: "deleted_at is null")
    create unique_index(:actors, [:project_id, :email], where: "deleted_at is null")
    create unique_index(:actors, [:project_id, :phone], where: "deleted_at is null")
    create unique_index(:actors, [:project_id, :user_id], where: "deleted_at is null")

    create table(:actions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :outcome, :string, null: false

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create index(:actions, [:actor_id])
    create index(:actions, [:outcome])

    ## Activity Logs

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

      # Projects
      add :project_id, references(:projects, type: :uuid, on_delete: :nilify_all)

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
    create index(:activity_logs, [:project_id])
    create index(:activity_logs, [:billing_customer_id])
    create index(:activity_logs, [:billing_subscription_id])

    execute "create index activity_logs_happened_at_idx on activity_logs ((happened_at::date));"
  end
end
