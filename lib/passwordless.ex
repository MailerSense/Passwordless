defmodule Passwordless do
  @moduledoc """
  Passwordless keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Ecto.Query
  import Util.Crud

  alias Database.Tenant
  alias Passwordless.Action
  alias Passwordless.ActionEvent
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Authenticators
  alias Passwordless.AuthToken
  alias Passwordless.Challenge
  alias Passwordless.Domain
  alias Passwordless.DomainRecord
  alias Passwordless.Email
  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplates
  alias Passwordless.EmailTemplateVersion
  alias Passwordless.Mailer
  alias Passwordless.MailerExecutor
  alias Passwordless.Organizations.Org
  alias Passwordless.Phone
  alias Passwordless.RecoveryCodes
  alias Passwordless.Repo
  alias Passwordless.Rule

  @authenticators [
    email: Authenticators.Email,
    sms: Authenticators.SMS,
    whatsapp: Authenticators.WhatsApp,
    magic_link: Authenticators.MagicLink,
    totp: Authenticators.TOTP,
    security_key: Authenticators.SecurityKey,
    passkey: Authenticators.Passkey,
    recovery_codes: Authenticators.RecoveryCodes
  ]

  @doc """
  Looks up `Application` config or raises if keyspace is not configured.
  ## Examples
      config :passwordless, :files, [
        uploads_dir: Path.expand("../priv/uploads", __DIR__),
        host: [scheme: "http", host: "localhost", port: 4000],
      ]
      iex> Passwordless.config([:files, :uploads_dir])
      iex> Passwordless.config([:files, :host, :port])
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
  end

  def create_full_app(%Org{} = org, attrs \\ %{}) do
    Repo.transact(fn ->
      with {:ok, app} <- create_app(org, attrs),
           {:ok, _authenticators} <-
             create_authenticators(app, %{
               magic_link: %{
                 sender: "verify",
                 sender_name: app.name,
                 redirect_urls: [%{url: app.website}]
               },
               email: %{
                 sender: "verify",
                 sender_name: app.name
               },
               totp: %{
                 issuer_name: app.name
               },
               security_key: %{
                 relying_party_id: URI.parse(app.website).host,
                 expected_origins: [%{url: app.website}]
               },
               passkey: %{
                 relying_party_id: URI.parse(app.website).host,
                 expected_origins: [%{url: app.website}]
               }
             }),
           do: {:ok, app}
    end)
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

  ## API Keys

  def get_auth_token!(%App{} = app, id) when is_binary(id) do
    app
    |> AuthToken.get_by_app()
    |> Repo.get!(id)
  end

  def create_auth_token(%App{} = app, attrs \\ %{}) do
    {signed_key, changeset} = AuthToken.new(app, attrs)

    with {:ok, auth_token} <- Repo.insert(changeset) do
      {:ok, auth_token, signed_key}
    end
  end

  def change_auth_token(%AuthToken{} = auth_token, attrs \\ %{}) do
    if Ecto.get_meta(auth_token, :state) == :loaded do
      AuthToken.changeset(auth_token, attrs)
    else
      AuthToken.create_changeset(auth_token, attrs)
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

  def get_domain!(%App{} = app) do
    Repo.one!(Ecto.assoc(app, :domain))
  end

  def get_domain(domain_id) when is_binary(domain_id) do
    case Repo.get(Domain, domain_id) do
      %Domain{} = domain -> {:ok, domain}
      _ -> {:error, :not_found}
    end
  end

  def list_domain_record(%Domain{} = domain) do
    DomainRecord.order(Repo.preload(domain, :records).records)
  end

  def create_domain(%App{} = app, attrs \\ %{}) do
    app
    |> Ecto.build_assoc(:domain)
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
           {:ok, domain} <- create_domain(app, attrs),
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
    |> Enum.sort_by(&Map.get(order, &1))
  end

  def fetch_authenticator(%App{} = app, key) do
    with {:ok, mod} <- Keyword.fetch(@authenticators, key) do
      case app |> Repo.preload(key) |> get_in([Access.key(key)]) do
        %^mod{} = authenticator -> {:ok, authenticator}
        _ -> {:error, :not_found}
      end
    end
  end

  crud(:magic_link, :magic_link, Passwordless.Authenticators.MagicLink)
  crud(:email, :email, Passwordless.Authenticators.Email)
  crud(:sms, :sms, Passwordless.Authenticators.SMS)
  crud(:whatsapp, :whatsapp, Passwordless.Authenticators.WhatsApp)
  crud(:totp, :totp, Passwordless.Authenticators.TOTP)
  crud(:security_key, :security_key, Passwordless.Authenticators.SecurityKey)
  crud(:passkey, :passkey, Passwordless.Authenticators.Passkey)
  crud(:recovery_codes, :recovery_codes, Passwordless.Authenticators.RecoveryCodes)

  # Actor

  def get_actor!(%App{} = app, id) when is_binary(id) do
    Actor
    |> Repo.get!(id, prefix: Tenant.to_prefix(app))
    |> Repo.preload([:email, :phone])
    |> Actor.put_active()
    |> Actor.put_text_properties()
  end

  def lookup_actor(%App{} = app, key) when is_binary(key) do
    query =
      if String.starts_with?(key, Actor.prefix()) do
        [id: key]
      else
        [user_id: key]
      end

    actor =
      Actor
      |> Repo.get_by(query, prefix: Tenant.to_prefix(app))
      |> Repo.preload([:email, :phone])

    case actor do
      %Actor{} = actor ->
        {:ok,
         actor
         |> Actor.put_active()
         |> Actor.put_text_properties()}

      nil ->
        {:error, :not_found}
    end
  end

  def create_actor(%App{} = app, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    %Actor{}
    |> Actor.changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def change_actor(%App{} = app, %Actor{} = actor, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    if Ecto.get_meta(actor, :state) == :loaded do
      Actor.changeset(actor, attrs, opts)
    else
      Actor.create_changeset(actor, attrs, opts)
    end
  end

  def update_actor(%App{} = app, %Actor{} = actor, attrs) do
    opts = [prefix: Tenant.to_prefix(app)]

    actor
    |> Actor.changeset(attrs, opts)
    |> Repo.update(opts)
  end

  def update_actor_properties(%App{} = app, %Actor{} = actor, attrs) do
    actor
    |> Actor.properties_changeset(attrs)
    |> Repo.update(prefix: Tenant.to_prefix(app))
  end

  def delete_actor(%App{} = app, %Actor{} = actor) do
    Repo.soft_delete(actor, prefix: Tenant.to_prefix(app))
  end

  def add_email(%App{} = app, %Actor{} = actor, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    actor
    |> Ecto.build_assoc(:emails)
    |> Email.changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def add_regional_phone(%App{} = app, %Actor{} = actor, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    actor
    |> Ecto.build_assoc(:phones)
    |> Phone.regional_changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def add_canonical_phone(%App{} = app, %Actor{} = actor, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    actor
    |> Ecto.build_assoc(:phones)
    |> Phone.canonical_changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def get_email!(%App{} = app, %Actor{} = actor, id) do
    actor
    |> Ecto.assoc(:emails)
    |> Repo.get!(id, prefix: Tenant.to_prefix(app))
    |> Email.put_virtuals()
  end

  def change_actor_email(%App{} = app, %Email{} = email, attrs \\ %{}) do
    Email.changeset(email, attrs, prefix: Tenant.to_prefix(app))
  end

  def create_actor_email(%App{} = app, %Actor{} = actor, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    actor
    |> Ecto.build_assoc(:emails)
    |> Email.changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def update_actor_email(%App{} = app, %Email{} = email, attrs) do
    opts = [prefix: Tenant.to_prefix(app)]

    email
    |> Email.changeset(attrs, opts)
    |> Repo.update(opts)
  end

  def list_emails(%App{} = app, %Actor{} = actor) do
    actor
    |> Ecto.assoc(:emails)
    |> Repo.all(prefix: Tenant.to_prefix(app))
  end

  def get_phone!(%App{} = app, %Actor{} = actor, id) do
    actor
    |> Ecto.assoc(:phones)
    |> Repo.get!(id, prefix: Tenant.to_prefix(app))
    |> Phone.put_virtuals()
  end

  def change_actor_phone(%App{} = app, %Phone{} = phone, attrs \\ %{}) do
    Phone.canonical_changeset(phone, attrs, prefix: Tenant.to_prefix(app))
  end

  def create_actor_phone(%App{} = app, %Actor{} = actor, attrs \\ %{}) do
    opts = [prefix: Tenant.to_prefix(app)]

    actor
    |> Ecto.build_assoc(:phones)
    |> Phone.canonical_changeset(attrs, opts)
    |> Repo.insert(opts)
  end

  def update_actor_phone(%App{} = app, %Phone{} = phone, attrs) do
    opts = [prefix: Tenant.to_prefix(app)]

    phone
    |> Phone.canonical_changeset(attrs, opts)
    |> Repo.update(opts)
  end

  def list_phones(%App{} = app, %Actor{} = actor) do
    actor
    |> Ecto.assoc(:phones)
    |> Repo.all(prefix: Tenant.to_prefix(app))
  end

  def get_actor_recovery_codes!(%App{} = app, %Actor{} = actor) do
    actor
    |> Ecto.assoc(:recovery_codes)
    |> Repo.one!(prefix: Tenant.to_prefix(app))
  end

  def create_actor_recovery_codes(%App{} = app, %Actor{} = actor) do
    opts = [prefix: Tenant.to_prefix(app)]

    actor
    |> Ecto.build_assoc(:recovery_codes)
    |> RecoveryCodes.changeset(opts)
    |> Repo.insert(opts)
  end

  # Action

  def continue(%App{} = app, %{action_id: id, event: event, payload: payload}) do
    opts = [prefix: Tenant.to_prefix(app)]

    # Repo.transact(fn ->
    #   with %Action{flow_data: %mod{} = data} = action <- Repo.get(Action, id, opts),
    #        {:ok, new_data} <- apply(mod, :trigger, [data, event, payload]),
    #        {:ok, new_action} <- action |> Action.changeset(%{data: new_data}) |> Repo.update(opts),
    #        {:ok, event} <- insert_action_event(app, action, new_action, %{event: event}),
    #        do: {:ok, new_action, event}
    # end)
  end

  # Action

  def get_action!(%App{} = app, id) do
    Action
    |> Repo.get!(id, prefix: Tenant.to_prefix(app))
    |> Repo.preload([
      :action_events,
      {:challenge, [:email_message]},
      actor: [:email, :phone]
    ])
  end

  def create_action(%App{} = app, %Actor{} = actor, attrs \\ %{}) do
    actor
    |> Ecto.build_assoc(:actions)
    |> Action.changeset(attrs)
    |> Repo.insert(prefix: Tenant.to_prefix(app))
  end

  def update_action_in_flow(%App{} = app, %Action{} = action, attrs \\ %{}) do
    action
    |> Action.changeset(attrs)
    |> Repo.update(prefix: Tenant.to_prefix(app))
  end

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

  # Event

  def create_event(%App{} = app, %Action{} = action, attrs \\ %{}) do
    action
    |> Ecto.build_assoc(:action_events)
    |> ActionEvent.changeset(attrs)
    |> Repo.insert(prefix: Tenant.to_prefix(app))
  end

  # Rules

  def get_rule!(%App{} = app, id) do
    Repo.get!(Action, id, prefix: Tenant.to_prefix(app))
  end

  def create_rule(%App{} = app, attrs \\ %{}) do
    %Rule{}
    |> Rule.changeset(attrs)
    |> Repo.insert(prefix: Tenant.to_prefix(app))
  end

  # Email templates

  def seed_email_template(%App{} = app, preset, language) do
    Repo.transact(fn ->
      settings = EmailTemplates.get_seed(app, preset, language)
      version_settings = Map.merge(%{language: language}, settings)

      with {:ok, template} <- create_email_template(app, Map.take(settings, [:name])),
           {:ok, version} <- create_email_template_version(template, version_settings),
           do: {:ok, %EmailTemplate{template | versions: [version]}}
    end)
  end

  def get_email_template_version(%EmailTemplate{} = email_template, language \\ :en) do
    email_template
    |> Ecto.assoc(:versions)
    |> where(language: ^language)
    |> Repo.one()
  end

  def get_email_template!(%App{} = app, id) do
    app
    |> Ecto.assoc(:email_templates)
    |> Repo.get!(id)
  end

  def get_or_create_email_template_version(%App{} = app, %EmailTemplate{} = email_template, language) do
    case get_email_template_version(email_template, language) do
      %EmailTemplateVersion{} = version ->
        version

      nil ->
        preset = :magic_link_sign_in
        settings = EmailTemplates.get_seed(app, preset, language)
        attrs = Map.merge(%{language: language}, settings)

        email_template
        |> Ecto.build_assoc(:versions)
        |> EmailTemplateVersion.changeset(attrs)
        |> Repo.insert!()
    end
  end

  def create_email_template_version(%EmailTemplate{} = email_template, attrs \\ %{}) do
    email_template
    |> Ecto.build_assoc(:versions)
    |> EmailTemplateVersion.changeset(attrs)
    |> Repo.insert()
  end

  def change_email_template_version(%EmailTemplateVersion{} = version, attrs \\ %{}) do
    if Ecto.get_meta(version, :state) == :loaded do
      EmailTemplateVersion.changeset(version, attrs)
    else
      EmailTemplateVersion.changeset(version, attrs)
    end
  end

  def update_email_template_version(%EmailTemplateVersion{} = version, attrs \\ %{}) do
    version
    |> EmailTemplateVersion.changeset(attrs)
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
    Repo.exists?(
      app
      |> Ecto.build_assoc(:email_templates)
      |> where(kind: ^kind)
    )
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
    Cache.with(
      "top_actions_#{app.id}",
      fn -> get_top_actions(app) end,
      ttl: :timer.hours(1)
    )
  end

  def get_app_user_count(%App{} = app) do
    Repo.aggregate(
      from(a in Actor,
        prefix: ^Tenant.to_prefix(app),
        select: count(a.id)
      ),
      :count,
      :id
    )
  end

  def get_app_user_count_cached(%App{} = app) do
    Cache.with(
      "app_user_count_#{app.id}",
      fn -> get_app_user_count(app) end,
      ttl: :timer.hours(1)
    )
  end

  def get_app_mau_count(%App{} = app, %Date{year: year, month: month}) do
    Repo.aggregate(
      from(a in Actor,
        as: :actor,
        prefix: ^Tenant.to_prefix(app),
        select: count(a.id),
        where:
          exists(
            from(
              c in Action,
              prefix: ^Tenant.to_prefix(app),
              where:
                c.actor_id == parent_as(:actor).id and
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
    Cache.with(
      "app_mau_count_#{app.id}_#{date.year}_#{date.month}",
      fn -> get_app_mau_count(app, date) end,
      ttl: :timer.hours(1)
    )
  end

  @doc """
  Deliver a pin code to sign in without a password.
  """
  def deliver_email_otp(%App{} = app, %Actor{} = actor, %Action{} = action, %Email{} = email, attrs \\ %{}) do
    nil
  end

  # Private

  defp deliver(%Swoosh.Email{} = email) do
    with {:ok, _job} <- enqueue_worker(Mailer.to_map(email)) do
      {:ok, email}
    end
  end

  defp enqueue_worker(email) do
    %{email: email}
    |> MailerExecutor.new()
    |> Oban.insert()
  end
end
