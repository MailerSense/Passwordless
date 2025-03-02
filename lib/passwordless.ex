defmodule Passwordless do
  @moduledoc """
  Passwordless keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Util.Crud

  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.DomainRecord
  alias Passwordless.Email
  alias Passwordless.Methods
  alias Passwordless.Organizations.Org
  alias Passwordless.Phone
  alias Passwordless.Repo

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

  ## Methods

  def methods, do: ~w(magic_link email_otp sms_otp push security_key passkey)a

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
           {:ok, _methods} <-
             create_methods(app, %{
               magic_link: %{
                 sender: "notifications",
                 sender_name: app.name
               },
               email: %{
                 sender: "notifications",
                 sender_name: app.name
               },
               authenticator: %{
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

  # Domains

  def get_domain!(%App{} = app) do
    Repo.one!(Ecto.assoc(app, :domain))
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

  # Methods

  def create_methods(%App{} = app, defaults \\ %{}) do
    methods = [
      magic_link: Methods.MagicLink,
      email: Methods.Email,
      sms: Methods.SMS,
      authenticator: Methods.Authenticator,
      security_key: Methods.SecurityKey,
      passkey: Methods.Passkey
    ]

    Repo.transact(fn ->
      methods =
        methods
        |> Enum.reject(fn {key, _mod} ->
          Repo.exists?(Ecto.assoc(app, key))
        end)
        |> Enum.map(fn {key, mod} ->
          app
          |> Ecto.build_assoc(key)
          |> mod.changeset(Map.get(defaults, key, %{}))
          |> Repo.insert!()
        end)

      {:ok, methods}
    end)
  end

  crud(:magic_link, :magic_link, Passwordless.Methods.MagicLink)
  crud(:email, :email, Passwordless.Methods.Email)
  crud(:sms, :sms, Passwordless.Methods.SMS)
  crud(:authenticator, :authenticator, Passwordless.Methods.Authenticator)
  crud(:security_key, :security_key, Passwordless.Methods.SecurityKey)
  crud(:passkey, :passkey, Passwordless.Methods.Passkey)

  # Actor

  def get_actor!(%App{} = app, id) when is_binary(id) do
    app
    |> Ecto.assoc(:actors)
    |> Repo.get!(id)
  end

  def create_actor(%App{} = app, attrs \\ %{}) do
    app
    |> Ecto.build_assoc(:actors)
    |> Actor.changeset(attrs)
    |> Repo.insert()
  end

  def change_actor(%Actor{} = actor, attrs \\ %{}) do
    if Ecto.get_meta(actor, :state) == :loaded do
      Actor.changeset(actor, attrs)
    else
      Actor.create_changeset(actor, attrs)
    end
  end

  def update_actor(%Actor{} = actor, attrs) do
    actor
    |> Actor.changeset(attrs)
    |> Repo.update()
  end

  def delete_actor(%Actor{} = actor) do
    Repo.soft_delete(actor)
  end

  def add_email(%Actor{} = actor, attrs \\ %{}) do
    actor
    |> Ecto.build_assoc(:emails)
    |> Email.changeset(Map.put(attrs, :app_id, actor.app_id))
    |> Repo.insert()
  end

  def add_regional_phone(%Actor{} = actor, attrs \\ %{}) do
    actor
    |> Ecto.build_assoc(:phones)
    |> Phone.regional_changeset(Map.put(attrs, :app_id, actor.app_id))
    |> Repo.insert()
  end

  def add_canonical_phone(%Actor{} = actor, attrs \\ %{}) do
    actor
    |> Ecto.build_assoc(:phones)
    |> Phone.canonical_changeset(Map.put(attrs, :app_id, actor.app_id))
    |> Repo.insert()
  end

  def list_emails(%Actor{} = actor) do
    actor
    |> Ecto.assoc(:emails)
    |> Repo.all()
  end

  def list_phones(%Actor{} = actor) do
    actor
    |> Ecto.assoc(:phones)
    |> Repo.all()
  end

  # Action

  def create_action(%Actor{} = actor, attrs \\ %{}) do
    actor
    |> Ecto.build_assoc(:actions)
    |> Action.changeset(Map.put(attrs, :app_id, actor.app_id))
    |> Repo.insert()
  end
end
