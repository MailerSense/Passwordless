defmodule Passwordless.Security.Guard do
  @moduledoc """
  API for guarding user actions based on their role in their organization.
  """
  import Ecto.Query

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org
  alias Passwordless.Repo

  @doc """
  Authorize a user's action on a resource by checking his role in the resource owning organization.
  """
  def permit(policy, %User{} = user, action, resource) when is_atom(policy) and is_atom(action) and is_struct(resource) do
    case get_role_for_resource(user, resource) do
      role when is_atom(role) -> policy.authorize(%User{user | role: role}, action, resource)
      _ -> false
    end
  end

  @doc """
  Authorize a user's action without a concrete resource instance.
  """
  def permit(policy, %User{} = user, action) when is_atom(policy) and is_atom(action) do
    policy.authorize(user, action, nil)
  end

  @doc """
  Check if a user has a specific role in a resource owning organization.
  """
  def is?(%User{} = user, resource, role) when is_atom(role) do
    case get_role_for_resource(user, resource) do
      ^role -> true
      _ -> false
    end
  end

  # Private

  defp get_role_for_resource(%User{id: user_id}, resource) when is_struct(resource) do
    base_query =
      from m in Membership,
        as: :membership,
        where: m.user_id == ^user_id,
        select: m.role

    if query = query_for(resource, base_query), do: Repo.one(query), else: []
  end

  defp query_for(%Org{id: org_id}, query) when is_binary(org_id), do: query_for_org_resource(org_id, query)
  defp query_for(%User{id: user_id}, query) when is_binary(user_id), do: query_for_user_resource(user_id, query)
  defp query_for(%{org_id: org_id}, query) when is_binary(org_id), do: query_for_org_resource(org_id, query)
  defp query_for(%{user_id: user_id}, query) when is_binary(user_id), do: query_for_user_resource(user_id, query)
  defp query_for(_resource, _query), do: nil

  defp query_for_user_resource(user_id, query) when is_binary(user_id) do
    query
    |> join(:inner, [membership: m], assoc(m, :org), as: :org)
    |> join(:inner, [org: o], assoc(o, :memberships), as: :other_membership)
    |> where([other_membership: m], m.user_id == ^user_id)
  end

  defp query_for_org_resource(org_id, query) when is_binary(org_id) do
    where(query, [membership: m], m.org_id == ^org_id)
  end
end
