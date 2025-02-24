defmodule Passwordless do
  @moduledoc """
  Passwordless keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Organizations.Org
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

  def get_app_by_slug!(%Org{} = org, slug) when is_binary(slug) do
    org
    |> Ecto.assoc(:apps)
    |> Repo.get_by!(slug: slug)
  end

  def create_app(%Org{} = org, attrs \\ %{}) do
    org
    |> Ecto.build_assoc(:apps)
    |> App.insert_changeset(attrs)
    |> Repo.insert()
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
      App.insert_changeset(app, attrs)
    end
  end

  def delete_app(%App{} = app) do
    Repo.soft_delete(app)
  end

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
      Actor.changeset(actor, attrs)
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

  # Action

  def create_action(%Actor{} = actor, attrs \\ %{}) do
    actor
    |> Ecto.build_assoc(:actions)
    |> Action.changeset(attrs)
    |> Repo.insert()
  end
end
