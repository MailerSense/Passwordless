defmodule PasswordlessWeb.ObanResolver do
  @moduledoc false
  @behaviour Oban.Web.Resolver

  alias Passwordless.Accounts.User

  @impl true
  def resolve_user(conn) do
    case conn.assigns[:current_user] do
      %User{} = user -> user
      _ -> nil
    end
  end

  @impl true
  def resolve_access(_user), do: :all

  @impl true
  def resolve_refresh(_user), do: 1

  @impl true
  def format_job_args(%Oban.Job{args: args}) do
    inspect(args, charlists: :as_lists, pretty: true)
  end

  @impl true
  def format_job_meta(%Oban.Job{meta: meta}) do
    inspect(meta, charlists: :as_lists, pretty: true)
  end

  @impl true
  def format_recorded(recorded, _job) do
    recorded
    |> Oban.Web.Resolver.decode_recorded()
    |> inspect(charlists: :as_lists, pretty: true)
  end

  @impl true
  def jobs_query_limit(_state), do: 100_000

  @impl true
  def hint_query_limit(_qualifier), do: 10_000
end
