defmodule Passwordless do
  @moduledoc """
  Passwordless authentication made easy.
  """

  import Ecto.Query
  import Util.Crud

  alias Database.PrefixedUUID
  alias Database.Tenant
  alias Passwordless.Action
  alias Passwordless.ActionEvent
  alias Passwordless.ActionTemplate
  alias Passwordless.App
  alias Passwordless.Authenticators
  alias Passwordless.AuthToken
  alias Passwordless.Challenge
  alias Passwordless.Challenges
  alias Passwordless.Domain
  alias Passwordless.DomainRecord
  alias Passwordless.Email
  alias Passwordless.EmailMessage
  alias Passwordless.EmailMessageMapping
  alias Passwordless.EmailOptOut
  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateLocale
  alias Passwordless.EmailTemplates
  alias Passwordless.EmailTemplateStyle
  alias Passwordless.EmailUnsubscribeLinkMapping
  alias Passwordless.Media
  alias Passwordless.Organizations.Org
  alias Passwordless.Phone
  alias Passwordless.RecoveryCodes
  alias Passwordless.Repo
  alias Passwordless.Rule
  alias Passwordless.User

  @authenticators [
    email_otp: Authenticators.EmailOTP,
    magic_link: Authenticators.MagicLink,
    passkey: Authenticators.Passkey,
    security_key: Authenticators.SecurityKey,
    totp: Authenticators.TOTP,
    recovery_codes: Authenticators.RecoveryCodes
  ]

  @challenges [
    email_otp: Challenges.EmailOTP,
    magic_link: Challenges.MagicLink,
    totp: Challenges.TOTP,
    recovery_codes: Challenges.RecoveryCodes
  ]

  @doc """
  Looks up `Application` config or raises if keyspace is not configured.
  """
  def config([main_key | rest] = keyspace) when is_list(keyspace) do
    main = Application.fetch_env!(:passwordless, main_key)

    Enum.reduce(rest, main, fn next_key, current ->
      case Keyword.fetch(current, next_key) do
        {:ok, val} -> val
        :error -> raise ArgumentError, "no config found under #{inspect(keyspace)}"
      end
    end)
  end

  def config(key, default \\ nil) when is_atom(key) do
    Application.get_env(:passwordless, key, default)
  end

  ## Apps

  def get_app(id) when is_binary(id) do
    Repo.get(App, id)
  end

  def get_app(%Org{} = org, id) when is_binary(id) do
    org
    |> Ecto.assoc(:apps)
    |> Repo.get(id)
  end

  def get_app!(%Org{} = org, id) when is_binary(id) do
    org
    |> Ecto.assoc(:apps)
    |> Repo.get!(id)
  end

  def create_app(%Org{} = org, attrs \\ %{}) do
    org
    |> Ecto.build_assoc(:apps)
    |> App.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, app} -> {:ok, Repo.preload(app, :settings)}
      error -> error
    end
  end

  def create_full_app(%Org{} = org, attrs \\ %{}) do
    fn ->
      with {:ok, app} <- create_app(org, attrs),
           {:ok, _auth_token} <- create_auth_token(app, %{permissions: [:actions]}),
           {:ok, magic_link_template} <-
             seed_email_template(app, :magic_link, :en, :magic_link_clean, %{tags: [:magic_link]}),
           {:ok, email_otp_template} <-
             seed_email_template(app, :email_otp, :en, :email_otp_clean, %{tags: [:email_otp]}),
           {:ok, _authenticators} <-
             create_authenticators(app, %{
               magic_link: %{
                 sender: "verify",
                 sender_name: app.name,
                 redirect_urls: [%{url: app.settings.website}],
                 email_template_id: magic_link_template.id
               },
               email_otp: %{
                 sender: "verify",
                 sender_name: app.name,
                 email_template_id: email_otp_template.id
               },
               passkey: %{
                 relying_party_id: URI.parse(app.settings.website).host,
                 expected_origins: [%{url: app.settings.website}]
               },
               security_key: %{
                 relying_party_id: URI.parse(app.settings.website).host,
                 expected_origins: [%{url: app.settings.website}]
               },
               totp: %{
                 issuer_name: app.name
               }
             }),
           do: {:ok, app}
    end
    |> Repo.transact()
    |> case do
      {:ok, app} ->
        with {:ok, _tenant} <- Tenant.create(app), do: {:ok, app}

      error ->
        error
    end
  end

  def update_app(%App{} = app, attrs) do
    app
    |> App.changeset(attrs)
    |> Repo.update()
  end

  def change_app(%App{} = app, attrs \\ %{}) do
    if Ecto.get_meta(app, :state) == :loaded do
      App.changeset(app, attrs)
    else
      App.changeset(app, attrs)
    end
  end

  def delete_app(%App{} = app) do
    Repo.soft_delete(app)
  end

  ## Media

  def get_media!(%App{} = app, id) when is_binary(id) do
    app
    |> Ecto.assoc(:media)
    |> Repo.get!(id)
  end

  def list_media(%App{} = app) do
    app
    |> Ecto.assoc(:media)
    |> Repo.all()
  end

  def create_media(%App{} = app, attrs \\ %{}) do
    app
    |> Ecto.build_assoc(:media)
    |> Media.changeset(attrs)
    |> Repo.insert()
  end

  def change_media(%Media{} = media, attrs \\ %{}) do
    if Ecto.get_meta(media, :state) == :loaded do
      Media.changeset(media, attrs)
    else
      Media.changeset(media, attrs)
    end
  end

  def delete_media(%Media{} = media) do
    Repo.soft_delete(media)
  end

  ## API Keys

  def get_auth_token!(%App{} = app, id) when is_binary(id) do
    app
    |> AuthToken.get_by_app()
    |> Repo.get!(id)
  end

  def create_auth_token(%App{} = app, attrs \\ %{}) do
    app
    |> Ecto.build_assoc(:auth_token)
    |> Kernel.then(&%AuthToken{&1 | key: AuthToken.generate_key()})
    |> AuthToken.changeset(attrs)
    |> Repo.insert()
  end

  def change_auth_token(%AuthToken{} = auth_token, attrs \\ %{}) do
    if Ecto.get_meta(auth_token, :state) == :loaded do
      AuthToken.changeset(auth_token, attrs)
    else
      AuthToken.changeset(auth_token, attrs)
    end
  end

  def update_auth_token(%AuthToken{} = auth_token, attrs \\ %{}) do
    auth_token
    |> AuthToken.changeset(attrs)
    |> Repo.update()
  end

  def revoke_auth_token(%AuthToken{} = auth_token) do
    auth_token
    |> AuthToken.changeset(%{state: :revoked})
    |> Repo.update()
  end

  # Domains

  def get_domain(id) when is_binary(id) do
    Repo.get(Domain, id)
  end

  def get_domain!(%App{} = app, id) do
    app
    |> Ecto.assoc(:domains)
    |> Repo.get!(id)
  end

  def fetch_domain(domain_id) when is_binary(domain_id) do
    case Repo.get(Domain, domain_id) do
      %Domain{} = domain -> {:ok, domain}
      _ -> {:error, :not_found}
    end
  end

  def list_domain_record(%Domain{} = domain) do
    DomainRecord.order(Repo.preload(domain, :records).records)
  end

  def create_email_domain(%App{} = app, attrs \\ %{}) do
    app
    |> Ecto.build_assoc(:email_domain)
    |> Kernel.then(&%Domain{&1 | purpose: :email})
    |> Domain.changeset(attrs)
    |> Repo.insert()
  end

  def create_tracking_domain(%App{} = app, attrs \\ %{}) do
    app
    |> Ecto.build_assoc(:tracking_domain)
    |> Kernel.then(&%Domain{&1 | purpose: :tracking})
    |> Domain.changeset(attrs)
    |> Repo.insert()
  end

  def create_domain_record(%Domain{} = domain, attrs \\ %{}) do
    domain
    |> Ecto.build_assoc(:records)
    |> DomainRecord.changeset(attrs)
    |> Repo.insert()
  end

  def change_domain(%Domain{} = domain, attrs \\ %{}) do
    if Ecto.get_meta(domain, :state) == :loaded do
      Domain.changeset(domain, attrs)
    else
      Domain.changeset(domain, attrs)
    end
  end

  def update_domain(%Domain{} = domain, attrs) do
    domain
    |> Domain.changeset(attrs)
    |> Repo.update()
  end

  def delete_domain(%Domain{} = domain) do
    Repo.soft_delete(domain)
  end

  def replace_domain(%App{} = app, %Domain{} = current_domain, attrs, records) do
    Repo.transact(fn ->
      with {:ok, _deleted} <- delete_domain(current_domain),
           {:ok, domain} <- create_email_domain(app, attrs),
           {:ok, records} <-
             Enum.reduce(records, {:ok, []}, fn record, {:ok, acc} ->
               case create_domain_record(domain, record) do
                 {:ok, record} -> {:ok, [record | acc]}
                 {:error, changeset} -> {:error, changeset}
               end
             end),
           do: {:ok, %Domain{domain | records: records}}
    end)
  end

  def replace_email_domain(%App{} = app, %Domain{purpose: :email} = current_domain, attrs) do
    Repo.transact(fn ->
      with {:ok, _deleted} <- delete_domain(current_domain),
           do: create_email_domain(app, attrs)
    end)
  end

  def replace_tracking_domain(%App{} = app, %Domain{purpose: :tracking} = current_domain, attrs) do
    Repo.transact(fn ->
      with {:ok, _deleted} <- delete_domain(current_domain),
           do: create_tracking_domain(app, attrs)
    end)
  end

  def teardown_domains(%App{} = app) do
    Repo.transact(fn ->
      with {_, _} <-
             app
             |> Ecto.assoc(:email_domain)
             |> Repo.delete_all(),
           {_, _} <-
             app
             |> Ecto.assoc(:tracking_domain)
             |> Repo.delete_all(),
           {:ok, app} <-
             app
             |> change_app(%{email_tracking: false, email_configuration_set: nil})
             |> Repo.update(),
           do: {:ok, %App{app | email_domain: nil, tracking_domain: nil}}
    end)
  end

  # Email Messages

  def get_email_message(%App{} = app, id) when is_binary(id) do
    Repo.get(EmailMessage, id, prefix: Tenant.to_prefix(app))
  end

  def record_email_message_mapping(%App{} = app, %EmailMessage{} = email_message, external_id) do
    app
    |> Ecto.build_assoc(:email_message_mappings)
    |> EmailMessageMapping.changeset(%{external_id: external_id, email_message_id: email_message.id})
    |> Repo.insert()
  end

  # Authenticators

  def create_authenticators(%App{} = app, defaults \\ %{}) do
    Repo.transact(fn ->
      authenticators =
        @authenticators
        |> Enum.reject(fn {key, _mod} ->
          Repo.exists?(Ecto.assoc(app, key))
        end)
        |> Enum.map(fn {key, mod} ->
          app
          |> Ecto.build_assoc(key)
          |> mod.changeset(Map.get(defaults, key, %{}))
          |> Repo.insert!()
        end)

      {:ok, authenticators}
    end)
  end

  def list_authenticators(%App{} = app) do
    names = Keyword.keys(@authenticators)

    order =
      @authenticators
      |> Enum.with_index()
      |> Map.new(fn {{k, _mod}, idx} -> {k, idx} end)

    app
    |> Repo.preload(Keyword.keys(@authenticators))
    |> Map.from_struct()
    |> Map.take(names)
    |> Map.reject(fn {_key, mod} -> Util.blank?(mod) end)
    |> Enum.sort_by(fn {key, _mod} -> Map.get(order, key) end)
  end

  def fetch_authenticator(%App{} = app, key) do
    with {:ok, mod} <- Keyword.fetch(@authenticators, key) do
      case app |> Repo.preload(key) |> get_in([Access.key(key)]) do
        %^mod{} = authenticator -> {:ok, authenticator}
        _ -> {:error, :not_found}
      end
    end
  end

  def get_fallback_domain(%App{} = app, purpose) when purpose in [:email, :tracking] do
    assoc =
      case purpose do
        :email -> :email_domain
        :tracking -> :tracking_domain
      end

    case Repo.preload(app, assoc) do
      %{^assoc => %Domain{purpose: ^purpose} = domain} ->
        {:ok, domain}

      _ ->
        case Domain
             |> Domain.get_by_purpose(purpose)
             |> Domain.get_by_tags([:system, :default])
             |> Repo.one() do
          %Domain{purpose: ^purpose} = domain -> {:ok, domain}
          _ -> {:error, :default_domain_not_found}
        end
    end
  end

  def get_fallback_domain!(%App{} = app, purpose) when purpose in [:email, :tracking] do
    {:ok, domain} = get_fallback_domain(app, purpose)
    domain
  end

  crud(:email_otp, :email, Passwordless.Authenticators.EmailOTP)
  crud(:magic_link, :magic_link, Passwordless.Authenticators.MagicLink)
  crud(:passkey, :passkey, Passwordless.Authenticators.Passkey)
  crud(:security_key, :security_key, Passwordless.Authenticators.SecurityKey)
  crud(:totp, :totp, Passwordless.Authenticators.TOTP)
  crud(:recovery_codes, :recovery_codes, Passwordless.Authenticators.RecoveryCodes)

  # User

  def get_user!(%App{} = app, id) when is_binary(id) do
    User
    |> Repo.get!(id, prefix: Tenant.to_prefix(app))
    |> Repo.preload([:email, :phone])
    |> User.put_text_data()
  end

  def resolve_user(%App{} = app, params) when is_map(params) do
    prefix = User.prefix()

    user_query =
      case params do
        %{id: id} when is_binary(id) ->
          case Database.PrefixedUUID.slug_to_uuid(id) do
            {:ok, ^prefix, _uuid} -> dynamic([a], a.id == ^id)
            _ -> false
          end

        %{username: username} when is_binary(username) ->
          dynamic([a], a.username == ^username)

        _ ->
          false
      end

    params = Map.put_new(params, :properties, %{})

    user_result =
      case Repo.one(from(u in User, where: ^user_query), prefix: Tenant.to_prefix(app)) do
        %User{} = user -> update_user(app, user, params)
        nil -> create_user(app, params)
      end

    with {:ok, %User{} = user} <- user_result,
         {:ok, %User{} = user} <- resolve_user_emails(app, user, params),
         do: {:ok, user}
  end

  def resolve_user_emails(%App{} = app, %User{} = user, %{emails: [_ | _] = emails}) do
    opts = [prefix: Tenant.to_prefix(app)]
    old_emails = Repo.preload(user, :emails).emails
    old_email_addresses = Map.new(old_emails, fn e -> {e.address, {:old, e}} end)
    new_email_addresses = Map.new(emails, fn %{address: a} = e -> {a, {:new, e}} end)

    diffs =
      Map.merge(old_email_addresses, new_email_addresses, fn _a, {:old, old}, {:new, new} ->
        {:changed, old, new}
      end)

    diffs
    |> Map.values()
    |> Enum.reduce_while([], fn
      {:new, attrs}, acc ->
        case user
             |> Ecto.build_assoc(:emails)
             |> Email.changeset(attrs, opts)
             |> Repo.insert(opts) do
          {:ok, email} -> {:cont, [email | acc]}
          {:error, changeset} -> {:halt, changeset}
        end

      {:changed, old, attrs}, acc ->
        case old
             |> Email.changeset(attrs, opts)
             |> Repo.update() do
          {:ok, email} -> {:cont, [email | acc]}
          {:error, changeset} -> {:halt, changeset}
        end

      {:old, email}, acc ->
        {:cont, [email | acc]}
    end)
    |> case do
      emails when is_list(emails) -> {:ok, Repo.preload(%User{user | emails: emails}, :email)}
      %Ecto.Changeset{} = changeset -> {:error, changeset}
    end
  end

  def resolve_user_emails(%User{} = user, _params) do
    {:ok, Repo.preload(user, :emails)}
  end

  def lookup_user(%App{} = app, id) when is_binary(id) do
    prefix = User.prefix()

    query =
      case Database.PrefixedUUID.slug_to_uuid(id) do
        {:ok, ^prefix, _uuid} -> [id: id]
        _ -> [username: id]
      end

    case User |> Repo.get_by(query, prefix: Tenant.to_prefix(app)) |> Repo.preload([:emails, :phones, :totps]) do
      %User{} = user -> {:ok, user}
      nil -> {:error, :not_found}
    end
  end

  def create_user(%App{} = app, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(opts)
  end

  def change_user(%App{} = app, %User{} = user, attrs \\ %{}) do
    if Ecto.get_meta(user, :state) == :loaded do
      User.changeset(user, attrs)
    else
      User.create_changeset(user, attrs)
    end
  end

  def update_user(%App{} = app, %User{} = user, attrs) do
    opts = [prefix: Tenant.to_prefix(app)]

    user
    |> User.changeset(attrs)
    |> Repo.update(opts)
  end

  def delete_user(%App{} = app, %User{} = user) do
    Repo.soft_delete(user, prefix: Tenant.to_prefix(app))
  end

  def add_user_email(%App{} = app, %User{} = user, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    user
    |> Ecto.build_assoc(:emails)
    |> Email.changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def add_user_regional_phone(%App{} = app, %User{} = user, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    user
    |> Ecto.build_assoc(:phones)
    |> Phone.regional_changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def add_user_canonical_phone(%App{} = app, %User{} = user, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    user
    |> Ecto.build_assoc(:phones)
    |> Phone.canonical_changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def change_user_email(%App{} = app, %Email{} = email, attrs \\ %{}) do
    Email.changeset(email, attrs, prefix: Tenant.to_prefix(app))
  end

  def create_user_email(%App{} = app, %User{} = user, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    user
    |> Ecto.build_assoc(:emails)
    |> Email.changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def update_user_email(%App{} = app, %Email{} = email, attrs) do
    opts = [prefix: Tenant.to_prefix(app)]

    email
    |> Email.changeset(attrs, opts)
    |> Repo.update(opts)
  end

  def list_user_emails(%App{} = app, %User{} = user) do
    user
    |> Ecto.assoc(:emails)
    |> Repo.all(prefix: Tenant.to_prefix(app))
  end

  def get_email_opt_out_reason(%App{} = app, %Email{address: address}) when is_binary(address) do
    opts = [prefix: Tenant.to_prefix(app)]

    case Repo.one(from(e in EmailOptOut, where: e.email == ^address), opts) do
      %EmailOptOut{reason: reason} -> reason
      _ -> nil
    end
  end

  def get_email_opt_out_reason(%App{}, %Email{}), do: nil

  def email_opted_out?(%App{} = app, %Email{address: address} = email) when is_binary(address) do
    if Email.opted_out?(email) do
      {:error, :email_opted_out}
    else
      opts = [prefix: Tenant.to_prefix(app)]

      if Repo.exists?(from(e in EmailOptOut, where: e.email == ^address), opts),
        do: {:error, :email_opted_out},
        else: :ok
    end
  end

  def email_opted_out?(%App{}, %Email{}), do: :ok

  def create_email_unsubscribe_link!(%App{} = app, %Email{} = email) do
    attrs = %{key: EmailUnsubscribeLinkMapping.generate_key(), email_id: email.id}

    changeset =
      app
      |> Ecto.build_assoc(:email_unsubscribe_link_mappings)
      |> EmailUnsubscribeLinkMapping.changeset(attrs)

    upsert_clause = [
      returning: true,
      on_conflict: :nothing,
      conflict_target: [:email_id]
    ]

    Repo.insert!(changeset, upsert_clause)
  end

  @doc """
  Get the unsubscribe link for an email.
  """
  def get_unsubscribe_link(token) when is_binary(token) do
    with {:ok, query} <- EmailUnsubscribeLinkMapping.get_by_token(token),
         {%EmailUnsubscribeLinkMapping{email_id: email_id} = mapping, %App{} = app} <- Repo.one(query) do
      app = Repo.preload(app, :settings)
      opts = [prefix: Tenant.to_prefix(app)]
      email_id = PrefixedUUID.uuid_to_slug(email_id, %{primary_key: true, prefix: Email.prefix()})
      {:ok, app, Repo.get(Email, email_id, opts), mapping}
    else
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Unsubscribe an email.
  """
  def unsubscribe_email(token, reason) when is_binary(token) do
    with {:ok, query} <- EmailUnsubscribeLinkMapping.get_by_token(token) do
      Repo.transact(fn ->
        case Repo.one(query) do
          {%EmailUnsubscribeLinkMapping{email_id: email_id} = mapping, %App{} = app} ->
            app = Repo.preload(app, :settings)
            opts = [prefix: Tenant.to_prefix(app)]
            email_id = PrefixedUUID.uuid_to_slug(email_id, %{primary_key: true, prefix: Email.prefix()})

            with %Email{} = email <- Repo.get(Email, email_id, opts),
                 {:ok, _mapping} <- Repo.delete(mapping),
                 {:ok, _opt_out} <- insert_email_opt_out(app, email, reason),
                 {:ok, email} <- opt_email_out(app, email),
                 do: {:ok, {app, email}}

          _ ->
            {:error, :link_not_found}
        end
      end)
    end
  end

  def opt_email_out(%App{} = app, %Email{} = email) do
    opts = [prefix: Tenant.to_prefix(app)]

    email
    |> Email.changeset(%{opted_out_at: DateTime.utc_now()}, opts)
    |> Repo.update(opts)
  end

  def insert_email_opt_out(%App{} = app, %Email{} = email, reason) do
    attrs = %{email: email.address, reason: reason}
    changeset = EmailOptOut.changeset(%EmailOptOut{}, attrs)

    upsert_clause = [
      prefix: Tenant.to_prefix(app),
      returning: true,
      on_conflict: :nothing,
      conflict_target: [:email]
    ]

    Repo.insert(changeset, upsert_clause)
  end

  def get_phone!(%App{} = app, %User{} = user, id) do
    user
    |> Ecto.assoc(:phones)
    |> Repo.get!(id, prefix: Tenant.to_prefix(app))
    |> Phone.put_virtuals()
  end

  def change_user_phone(%App{} = app, %Phone{} = phone, attrs \\ %{}) do
    Phone.canonical_changeset(phone, attrs, prefix: Tenant.to_prefix(app))
  end

  def create_user_phone(%App{} = app, %User{} = user, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    user
    |> Ecto.build_assoc(:phones)
    |> Phone.canonical_changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def update_user_phone(%App{} = app, %Phone{} = phone, attrs) do
    opts = [prefix: Tenant.to_prefix(app)]

    phone
    |> Phone.canonical_changeset(attrs, opts)
    |> Repo.update(opts)
  end

  def list_phones(%App{} = app, %User{} = user) do
    user
    |> Ecto.assoc(:phones)
    |> Repo.all(prefix: Tenant.to_prefix(app))
  end

  def get_user_recovery_codes!(%App{} = app, %User{} = user) do
    user
    |> Ecto.assoc(:recovery_codes)
    |> Repo.one!(prefix: Tenant.to_prefix(app))
  end

  def create_user_recovery_codes(%App{} = app, %User{} = user) do
    opts = [prefix: Tenant.to_prefix(app)]

    user
    |> Ecto.build_assoc(:recovery_codes)
    |> RecoveryCodes.changeset(opts)
    |> Repo.insert(opts)
  end

  # Action

  def get_action!(%App{} = app, id) do
    Action
    |> Repo.get!(id, prefix: Tenant.to_prefix(app))
    |> Repo.preload(user: [:email, :phone])
  end

  def get_action(%App{} = app, id) do
    Action
    |> Repo.get(id, prefix: Tenant.to_prefix(app))
    |> Repo.preload([:rule, {:user, [:email, :phone]}, {:challenge, [:email_message]}, :events])
    |> case do
      %Action{} = action -> {:ok, action}
      nil -> {:error, :not_found}
    end
  end

  def create_action(%App{} = app, %User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:actions)
    |> Action.changeset(attrs)
    |> Repo.insert(prefix: Tenant.to_prefix(app))
  end

  def create_action_template(%App{} = app, attrs \\ %{}) do
    app
    |> Ecto.build_assoc(:action_templates)
    |> ActionTemplate.changeset(attrs)
    |> Repo.insert()
  end

  def update_action_in_flow(%App{} = app, %Action{} = action, attrs \\ %{}) do
    action
    |> Action.changeset(attrs)
    |> Repo.update(prefix: Tenant.to_prefix(app))
  end

  # Action Event

  def get_action_event(%App{} = app, id) do
    Repo.get(ActionEvent, id, prefix: Tenant.to_prefix(app))
  end

  def update_action_event(%App{} = app, %ActionEvent{} = action_event, attrs) do
    action_event
    |> ActionEvent.changeset(attrs)
    |> Repo.update(prefix: Tenant.to_prefix(app))
  end

  def locate_action_event(%App{} = app, %ActionEvent{ip_address: ip_address} = event) when is_binary(ip_address) do
    key = "ip_loc_" <> ip_address

    case Passwordless.Cache.get(key) do
      %{"city" => city, "country" => country} when is_binary(city) and is_binary(country) ->
        Passwordless.update_action_event(app, event, %{city: city, country: country})

      _ ->
        %{app_id: app.id, action_event_id: event.id}
        |> Passwordless.ActionLocator.new()
        |> Oban.insert()
    end
  end

  def locate_action_event(%App{} = app, event), do: {:ok, event}

  # Challenge

  def get_challenge!(%App{} = app, id) do
    Repo.get!(Action, id, prefix: Tenant.to_prefix(app))
  end

  def get_challenge(%App{} = app, id) do
    Repo.get(Action, id, prefix: Tenant.to_prefix(app))
  end

  def create_challenge(%App{} = app, %Action{} = action, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    action
    |> Ecto.build_assoc(:challenges)
    |> Challenge.changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def handle_challenge(
        %App{} = app,
        %User{} = user,
        %Action{} = action,
        %Challenge{kind: kind} = challenge,
        event,
        attrs \\ %{}
      ) do
    action = %Action{action | challenge: challenge}
    mod = Keyword.fetch!(@challenges, kind)
    mod.handle(app, user, action, event: event, attrs: attrs)
  end

  # Event

  def create_event(%App{} = app, %Action{} = action, attrs \\ %{}) do
    action
    |> Ecto.build_assoc(:events)
    |> ActionEvent.changeset(attrs)
    |> Repo.insert(prefix: Tenant.to_prefix(app))
  end

  # Rules

  def get_rule!(%App{} = app, id) do
    Repo.get!(Action, id, prefix: Tenant.to_prefix(app))
  end

  def create_rule(%App{} = app, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]
    changeset = Rule.changeset(%Rule{}, attrs)

    with {:ok, rule} <- Ecto.Changeset.apply_action(changeset, :insert) do
      Repo.transact(fn ->
        case Repo.get_by(Rule, [hash: rule.hash], opts) do
          %Rule{} = rule -> {:ok, rule}
          nil -> Repo.insert(changeset, opts)
        end
      end)
    end
  end

  # Email templates

  def seed_email_template(%App{} = app, authenticator, language, style, attrs \\ %{}) do
    Repo.transact(fn ->
      app = Repo.preload(app, :settings)
      settings = app |> EmailTemplates.get_seed(authenticator, language, style) |> Map.merge(attrs)
      locale_attrs = Map.merge(%{language: language}, settings)

      with {:ok, template} <- create_email_template(app, Map.take(settings, [:name, :tags])),
           {:ok, locale} <- create_email_template_locale(template, locale_attrs),
           do: {:ok, %EmailTemplate{template | locales: [locale]}}
    end)
  end

  def reset_email_template(
        %App{} = app,
        %EmailTemplate{} = email_template,
        %EmailTemplateLocale{language: language, style: style} = email_template_locale
      ) do
    app = Repo.preload(app, :settings)
    settings = EmailTemplates.get_seed(app, hd(email_template.tags), language, style)
    attrs = Map.merge(%{language: language}, settings)

    email_template_locale
    |> EmailTemplateLocale.changeset(attrs)
    |> Repo.update()
  end

  def get_email_template_locale(%EmailTemplate{} = email_template, language \\ :en) do
    email_template
    |> Ecto.assoc(:locales)
    |> Repo.get_by(language: language)
  end

  def get_email_template!(%App{} = app, id) do
    app
    |> Ecto.assoc(:email_templates)
    |> Repo.get!(id)
  end

  def get_or_create_email_template_locale(%App{} = app, %EmailTemplate{} = email_template, language) do
    Repo.transact(fn ->
      case get_email_template_locale(email_template, language) do
        %EmailTemplateLocale{} = locale ->
          {:ok, locale}

        _ ->
          app = Repo.preload(app, :settings)
          settings = EmailTemplates.get_seed(app, hd(email_template.tags), language, nil)
          attrs = Map.merge(%{language: language}, settings)

          email_template
          |> Ecto.build_assoc(:locales)
          |> EmailTemplateLocale.changeset(attrs)
          |> Repo.insert()
      end
    end)
  end

  def create_email_template_locale(%EmailTemplate{} = email_template, attrs \\ %{}) do
    email_template
    |> Ecto.build_assoc(:locales)
    |> EmailTemplateLocale.changeset(attrs)
    |> Repo.insert()
  end

  def change_email_template_locale(%EmailTemplateLocale{} = locale, attrs \\ %{}, opts \\ []) do
    if Ecto.get_meta(locale, :state) == :loaded do
      EmailTemplateLocale.changeset(locale, attrs, opts)
    else
      EmailTemplateLocale.changeset(locale, attrs, opts)
    end
  end

  def update_email_template_locale(%EmailTemplateLocale{} = locale, attrs \\ %{}, opts \\ []) do
    locale
    |> EmailTemplateLocale.changeset(attrs, opts)
    |> Repo.update()
  end

  def create_email_template(%App{} = app, attrs \\ %{}) do
    app
    |> Ecto.build_assoc(:email_templates)
    |> EmailTemplate.changeset(attrs)
    |> Repo.insert()
  end

  def change_email_template(%EmailTemplate{} = email_template, attrs \\ %{}) do
    if Ecto.get_meta(email_template, :state) == :loaded do
      EmailTemplate.changeset(email_template, attrs)
    else
      EmailTemplate.changeset(email_template, attrs)
    end
  end

  def update_email_template(%EmailTemplate{} = email_template, attrs \\ %{}) do
    email_template
    |> EmailTemplate.changeset(attrs)
    |> Repo.update()
  end

  def email_template_exists?(%App{} = app, kind) do
    app
    |> Ecto.build_assoc(:email_templates)
    |> where(kind: ^kind)
    |> Repo.exists?()
  end

  def get_template_locale_style(%EmailTemplateLocale{} = locale, style) do
    locale
    |> Ecto.assoc(:styles)
    |> Repo.get_by(style: style)
  end

  def persist_template_locale_style!(%EmailTemplateLocale{} = locale) do
    attrs = %{style: locale.style, mjml_body: locale.mjml_body}

    changeset =
      locale
      |> Ecto.build_assoc(:styles)
      |> EmailTemplateStyle.changeset(attrs)

    upsert_clause = [
      on_conflict: {:replace, [:mjml_body, :updated_at]},
      conflict_target: [:email_template_locale_id, :style]
    ]

    Repo.insert!(changeset, upsert_clause)
  end

  def get_top_actions(%App{} = app) do
    Repo.all(
      from(a in Action,
        prefix: ^Tenant.to_prefix(app),
        where: a.state in [:allow, :timeout, :block],
        group_by: a.name,
        select: %{
          action: a.name,
          total: count(a.id),
          states: %{
            allow: a.id |> count() |> filter(a.state == :allow),
            timeout: a.id |> count() |> filter(a.state == :timeout),
            block: a.id |> count() |> filter(a.state == :block)
          }
        },
        having: count(a.id) > 0,
        order_by: [desc: count(a.id)],
        limit: 3
      )
    )
  end

  def get_top_actions_cached(%App{} = app) do
    Passwordless.Cache.with(
      "top_actions_#{app.id}",
      fn -> get_top_actions(app) end,
      ttl: :timer.hours(1)
    )
  end

  def get_app_user_count(%App{} = app) do
    Repo.aggregate(
      from(u in User, prefix: ^Tenant.to_prefix(app), select: count(u.id)),
      :count,
      :id
    )
  end

  def get_app_user_count_cached(%App{} = app) do
    Passwordless.Cache.with(
      "app_user_count_#{app.id}",
      fn -> get_app_user_count(app) end,
      ttl: :timer.hours(1)
    )
  end

  def get_app_mau_count(%App{} = app, %Date{year: year, month: month}) do
    Repo.aggregate(
      from(u in User,
        as: :user,
        prefix: ^Tenant.to_prefix(app),
        select: count(u.id),
        where:
          exists(
            from(
              c in Action,
              prefix: ^Tenant.to_prefix(app),
              where:
                c.user_id == parent_as(:user).id and
                  fragment("date_part('year', ?)", c.inserted_at) == ^year and
                  fragment("date_part('month', ?)", c.inserted_at) == ^month
            )
          )
      ),
      :count,
      :id
    )
  end

  def get_app_mau_count_cached(%App{} = app, date) do
    Passwordless.Cache.with(
      "app_mau_count_#{app.id}_#{date.year}_#{date.month}",
      fn -> get_app_mau_count(app, date) end,
      ttl: :timer.hours(1)
    )
  end
end
