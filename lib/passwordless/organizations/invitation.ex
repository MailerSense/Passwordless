defmodule Passwordless.Organizations.Invitation do
  @moduledoc false

  use Passwordless.Schema, prefix: "orginv"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org
  alias Passwordless.Repo

  @derive {
    Flop.Schema,
    sortable: [:id, :email], filterable: [:id]
  }
  schema "org_invitations" do
    field :email, :string

    belongs_to :org, Org
    belongs_to :user, User

    timestamps()
  end

  @doc """
  Get invitations for an organization.
  """
  def get_by_org(%Org{} = org) do
    from __MODULE__, where: [org_id: ^org.id]
  end

  @doc """
  Get invitations for a user.
  """
  def get_by_user(%User{} = user) do
    from __MODULE__, where: [user_id: ^user.id]
  end

  @doc """
  Find invitations by email and assign them to the user.
  """
  def assign_to_user_by_email(%User{} = user) do
    from __MODULE__,
      where: [email: ^user.email],
      update: [set: [user_id: ^user.id]]
  end

  @doc """
  Get invitations for users who already joined the org.
  """
  def get_stale_of_user(%User{id: user_id}) do
    from i in __MODULE__,
      join: o in assoc(i, :org),
      join: m in assoc(o, :memberships),
      where: m.user_id == ^user_id
  end

  @already_invited "is already invited"

  @doc """
  An invitation changeset to create a new invitation.
  """
  def changeset(%__MODULE__{} = invitation, attrs \\ %{}) do
    invitation
    |> cast(attrs, [:org_id, :email])
    |> validate_required([:org_id, :email])
    |> validate_email()
    |> validate_unique()
    |> put_user_id()
    |> ensure_user_not_already_in_org()
    |> assoc_constraint(:org)
    |> assoc_constraint(:user)
  end

  # Private

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> ChangesetExt.validate_email()
  end

  defp validate_unique(changeset) do
    changeset
    |> unique_constraint([:email, :org_id], message: @already_invited)
    |> unsafe_validate_unique([:email, :org_id], Repo, message: @already_invited)
  end

  defp put_user_id(%Ecto.Changeset{valid?: true} = changeset) do
    email = fetch_change!(changeset, :email)
    user = Accounts.get_user_by_email(email)

    if User.confirmed?(user) and User.active?(user),
      do: put_change(changeset, :user_id, user.id),
      else: changeset
  end

  defp put_user_id(changeset), do: changeset

  defp ensure_user_not_already_in_org(changeset) do
    org_id = fetch_field!(changeset, :org_id)
    user_id = get_change(changeset, :user_id)

    if user_id && Repo.exists?(from Membership, where: [org_id: ^org_id, user_id: ^user_id]) do
      add_error(changeset, :email, "is already in this organization")
    else
      changeset
    end
  end
end
