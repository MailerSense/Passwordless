defmodule Passwordless.Security.Policy.Accounts do
  @moduledoc """
  Security policy for the accounts context.
  """

  use Security.Policy

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.Membership

  @impl true
  def authorize(%User{id: id, role: :owner}, action, %Membership{user: %User{id: id}})
      when action in ~w(delete update_role)a,
      do: false

  @impl true
  def authorize(%User{id: id}, :"user.impersonate", %User{id: id}), do: false

  @impl true
  def authorize(%User{current_membership: %Membership{} = current}, :"user.impersonate", %User{} = _other) do
    Membership.is_or_higher?(current, :admin)
  end

  @impl true
  def authorize(%User{current_membership: %Membership{} = current}, _action, %Membership{} = other) do
    Membership.is_or_higher?(current, :manager) and Membership.access_level(current) <= Membership.access_level(other)
  end

  @impl true
  def authorize(%User{current_membership: %Membership{} = current}, :"org.update_profile", _org) do
    Membership.is_or_higher?(current, :manager)
  end

  @impl true
  def authorize(%User{} = user, :receive_email, :essential), do: User.active?(user)

  @impl true
  def authorize(%User{} = user, :receive_email, :non_essential), do: User.active?(user) and User.confirmed?(user)

  @impl true
  def authorize(%User{}, _action, _resource), do: false
end
