defmodule Passwordless.Organizations do
  @moduledoc """
  The organizations context.
  """

  alias Database.QueryExt
  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.AuthToken
  alias Passwordless.Organizations.Invitation
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org
  alias Passwordless.Repo

  ## Orgs

  @doc """
  Get an org by member and the slug.
  """
  def get_org(%User{} = user, id) when is_binary(id) do
    user
    |> Ecto.assoc(:orgs)
    |> Repo.get(id)
  end

  def get_org(_, _), do: nil

  @doc """
  Get an org by id.
  """
  def get_org(id) when is_binary(id) do
    Repo.get(Org, id)
  end

  def get_org(_), do: nil

  @doc """
  Get an org by member and the slug.
  """
  def get_org!(%User{} = user, org_id) when is_binary(org_id) do
    user
    |> Ecto.assoc(:orgs)
    |> Repo.get!(org_id)
  end

  @doc """
  Get an org by slug.
  """
  def get_org!(slug) when is_binary(slug) do
    Repo.get_by!(Org, slug: slug)
  end

  @doc """
  List all orgs.
  """
  def list_orgs do
    Repo.all(Org)
  end

  @doc """
  List all orgs for a user.
  """
  def list_orgs(%User{} = user) do
    Repo.preload(user, :orgs).orgs
  end

  @doc """
  List all apps for an org.
  """
  def list_apps(%Org{} = org) do
    Repo.preload(org, :apps).apps
  end

  @doc """
  Get an org by ID.
  """
  def get_org_by_id(id) when is_binary(id) do
    Repo.get(Org, id)
  end

  def get_org_by_id(_id), do: nil

  @doc """
  Get an org by ID.
  """
  def get_org_by_id!(id) do
    Repo.get!(Org, id)
  end

  @doc """
  Preload org memberships.
  """
  def preload_org_memberships(%Org{} = org) do
    Repo.preload(org, memberships: :user)
  end

  @doc """
  Create the org without the owner.
  """
  def create_org(attrs \\ %{}) do
    %Org{}
    |> Org.insert_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Create the org with the owner.
  """
  def create_org_with_owner(%User{} = user, attrs \\ %{}) do
    changeset = Org.insert_changeset(%Org{}, attrs)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:org, changeset)
      |> Ecto.Multi.insert(:membership, fn %{org: %Org{} = org} -> Membership.insert_changeset(org, user, :owner) end)

    case Repo.transaction(multi) do
      {:ok, %{org: org, membership: membership}} ->
        {:ok, org, membership}

      {:error, :org, changeset, _} ->
        {:error, changeset}
    end
  end

  def change_org(%Org{} = org, attrs \\ %{}) do
    if Ecto.get_meta(org, :state) == :loaded do
      Org.update_changeset(org, attrs)
    else
      Org.insert_changeset(org, attrs)
    end
  end

  def update_org(%Org{} = org, attrs \\ %{}) do
    org
    |> Org.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_org(%Org{} = org) do
    Repo.delete(org)
  end

  @doc """
  This will find any invitations for a user's email address and assign them to the user.
  It will also delete any invitations to orgs the user is already a member of.
  Run this after a user has confirmed or changed their email.
  """
  def sync_user_invitations(%User{} = user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:updated_invitations, Invitation.assign_to_user_by_email(user), [])
    |> Ecto.Multi.delete_all(:deleted_invitations, Invitation.get_stale_of_user(user))
    |> Repo.transaction()
  end

  ## Members

  def create_membership(%Org{} = org, %User{} = user, role \\ :member) when is_atom(role) do
    org
    |> Membership.insert_changeset(user, role)
    |> Repo.insert()
  end

  def delete_membership(%Membership{} = membership) do
    Repo.delete(membership)
  end

  def get_membership!(%User{} = user, org_id) when is_binary(org_id) do
    user
    |> Membership.get_by_user_and_org_id(org_id)
    |> QueryExt.preload([:org, :user])
    |> Repo.one!()
    |> Membership.assign_user()
  end

  def get_membership!(%Org{} = org, id) when is_binary(id) do
    org
    |> Membership.get_by_org()
    |> QueryExt.preload([:org, :user])
    |> Repo.get!(id)
    |> Membership.assign_user()
  end

  def change_membership(%Membership{} = membership, attrs \\ %{}) do
    Membership.changeset(membership, attrs)
  end

  def update_membership(%Membership{} = membership, attrs \\ %{}) do
    membership
    |> Membership.changeset(attrs)
    |> Repo.update()
  end

  ## Invitations - org based

  def build_invitation(%Org{} = org, attrs \\ %{}) do
    Invitation.changeset(%Invitation{org_id: org.id}, attrs)
  end

  def create_invitation(%Org{} = org, attrs \\ %{}) do
    %Invitation{org_id: org.id}
    |> Invitation.changeset(attrs)
    |> Repo.insert()
  end

  def get_invitation_by_org!(%Org{} = org, id) when is_binary(id) do
    org
    |> Invitation.get_by_org()
    |> Repo.get!(id)
  end

  def delete_invitation(%Invitation{} = invitation) do
    Repo.delete(invitation)
  end

  ## Invitations - user based

  defp get_invitation_by_user!(%User{} = user, id) when is_binary(id) do
    user
    |> Invitation.get_by_user()
    |> Repo.get!(id)
  end

  def list_invitations_by_user(%User{} = user) do
    user
    |> Invitation.get_by_user()
    |> Repo.all()
    |> Repo.preload(:org)
  end

  def accept_invitation!(%User{} = user, id) when is_binary(id) do
    invitation = get_invitation_by_user!(user, id)
    org = Repo.one!(Ecto.assoc(invitation, :org))

    {:ok, %{membership: membership}} =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:membership, Membership.insert_changeset(org, user))
      |> Ecto.Multi.delete(:invitation, invitation)
      |> Repo.transaction()

    %Membership{membership | org: org}
  end

  def reject_invitation!(%User{} = user, id) when is_binary(id) do
    invitation = get_invitation_by_user!(user, id)
    Repo.delete!(invitation)
  end

  ## API Keys

  def get_auth_token!(%Org{} = org, id) when is_binary(id) do
    org
    |> AuthToken.get_by_org()
    |> Repo.get!(id)
  end

  def create_auth_token(%Org{} = org, attrs \\ %{}) do
    {signed_key, changeset} = AuthToken.new(org, attrs)

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

  ## Projects

  def preload_apps(%Org{} = org) do
    Repo.preload(org, :apps)
  end
end
