defmodule Passwordless.Repo.TenantMigrations.CreateTables do
  use Ecto.Migration

  import Database.SoftDelete.Migration

  def change do
    execute "create extension if not exists citext", ""
    execute "create extension if not exists pg_trgm", ""

    ## Actors

    create table(:actors, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :state, :string, null: false
      add :language, :string, null: false

      timestamps()
      soft_delete_column()
    end

    create index(:actors, [:state], where: "deleted_at is null")

    execute "create index actors_name_gin_trgm_idx on #{prefix()}.actors using gin (name gin_trgm_ops);"

    ## Emails

    create table(:emails, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :address, :citext, null: false
      add :primary, :boolean, null: false, default: false
      add :verified, :boolean, null: false, default: false

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:emails, [:actor_id], where: "deleted_at is null")
    create unique_index(:emails, [:actor_id, :primary], where: "\"primary\"")
    create unique_index(:emails, [:actor_id, :address], where: "deleted_at is null")

    execute "create index emails_email_gin_trgm_idx on #{prefix()}.emails using gin (address gin_trgm_ops);"

    ## Phones

    create table(:phones, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :number, :citext, null: false
      add :region, :string, null: false
      add :canonical, :citext, null: false
      add :primary, :boolean, null: false, default: false
      add :verified, :boolean, null: false, default: false
      add :channels, {:array, :string}, null: false, default: []

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:phones, [:actor_id], where: "deleted_at is null")
    create unique_index(:phones, [:actor_id, :primary], where: "\"primary\"")
    create unique_index(:phones, [:actor_id, :canonical], where: "deleted_at is null")

    execute "create index phones_canonical_gin_trgm_idx on #{prefix()}.phones using gin (canonical gin_trgm_ops);"

    ## Identities

    create table(:identities, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :system, :string, null: false
      add :user_id, :string, null: false

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:identities, [:actor_id], where: "deleted_at is null")
    create unique_index(:identities, [:actor_id, :system, :user_id], where: "deleted_at is null")

    execute "create index identities_user_id_gin_trgm_idx on #{prefix()}.identities using gin (user_id gin_trgm_ops);"

    ## TOTPS

    create table(:totps, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :secret, :binary, null: false
      add :backup_codes, :map, null: false, default: %{}

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:totps, [:actor_id], where: "deleted_at is null")
    create unique_index(:totps, [:secret], where: "deleted_at is null")
    create unique_index(:totps, [:actor_id, :secret], where: "deleted_at is null")

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

    ## Action

    create table(:actions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :method, :string, null: false
      add :outcome, :string, null: false

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

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

      add :actor_id, references(:actors, type: :uuid, on_delete: :delete_all), null: false
      add :action_id, references(:actions, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
      soft_delete_column()
    end

    create index(:challenges, [:actor_id], where: "deleted_at is null")
    create unique_index(:challenges, [:token], where: "deleted_at is null")
    create unique_index(:challenges, [:actor_id, :token], where: "deleted_at is null")
    create unique_index(:challenges, [:actor_id, :action_id], where: "deleted_at is null")

    ## Events

    create table(:events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :state, :string, null: false
      add :details, :string
      add :ip_address, :string
      add :country, :string
      add :city, :string

      add :actor_id, references(:actors, type: :uuid, on_delete: :nilify_all)
      add :action_id, references(:actions, type: :uuid, on_delete: :nilify_all)
      add :challenge_id, references(:challenges, type: :uuid, on_delete: :nilify_all)

      timestamps(updated_at: false)
    end

    create index(:events, [:actor_id])
    create index(:events, [:action_id])
    create index(:events, [:challenge_id])
  end
end
