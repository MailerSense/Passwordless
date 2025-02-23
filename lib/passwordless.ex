defmodule Passwordless do
  @moduledoc """
  Passwordless keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.Organizations.Org
  alias Passwordless.Project
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

  ## Projects

  def get_project(%Org{} = org, id) when is_binary(id) do
    org
    |> Ecto.assoc(:projects)
    |> Repo.get(id)
  end

  def get_project!(%Org{} = org, id) when is_binary(id) do
    org
    |> Ecto.assoc(:projects)
    |> Repo.get!(id)
  end

  def get_project_by_slug!(%Org{} = org, slug) when is_binary(slug) do
    org
    |> Ecto.assoc(:projects)
    |> Repo.get_by!(slug: slug)
  end

  def create_project(%Org{} = org, attrs \\ %{}) do
    org
    |> Ecto.build_assoc(:projects)
    |> Project.insert_changeset(attrs)
    |> Repo.insert()
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def change_project(%Project{} = project, attrs \\ %{}) do
    if Ecto.get_meta(project, :state) == :loaded do
      Project.changeset(project, attrs)
    else
      Project.insert_changeset(project, attrs)
    end
  end

  def delete_project(%Project{} = project) do
    Repo.soft_delete(project)
  end

  # Actor

  def get_actor!(%Project{} = project, id) when is_binary(id) do
    project
    |> Ecto.assoc(:actors)
    |> Repo.get!(id)
  end

  def create_actor(%Project{} = project, attrs \\ %{}) do
    project
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
