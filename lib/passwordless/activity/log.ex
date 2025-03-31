defmodule Passwordless.Activity.Log do
  @moduledoc """
  The log of activity on key entities in the system.
  """

  use Passwordless.Schema, prefix: "actlog"

  import Ecto.Query

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Activity.Filter, as: ActivityFilter
  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Org

  @caregories ~w(org user)a
  @category_actions [
    org: ~w(
      org.update_profile
      org.update_member
      org.delete_member
      org.create_auth_token
      org.update_auth_token
      org.revoke_auth_token
      org.create_invitation
      org.delete_invitation
      org.accept_invitation
      org.reject_invitation
    )a,
    user: ~w(
      user.register
      user.activate
      user.lock
      user.unlock
      user.confirm
      user.sign_in
      user.sign_out
      user.impersonate
      user.end_impersonation
      user.update_profile
      user.confirm_email
      user.request_email_change
      user.request_magic_link
      user.request_password_reset
      user.reset_password
    )a,
    billing: ~w(
      subscription.created
      subscription.updated
      subscription.deleted
      subscription.paused
      subscription.resumed
      subscription.cancelled
      subscription.trial_will_be_ended
      subscription_item.created
      subscription_item.updated
      subscription_item.deleted
    )a
  ]
  @actions @category_actions |> Keyword.values() |> Enum.flat_map(& &1)

  @derive {
    Flop.Schema,
    filterable: [:search],
    sortable: [:id],
    custom_fields: [
      search: [
        filter: {__MODULE__, :unified_search_filter, []},
        ecto_type: :string
      ]
    ]
  }
  schema "activity_logs" do
    field :action, Ecto.Enum, values: @actions
    field :category, Ecto.Enum, values: @caregories
    field :metadata, :map
    field :happened_at, :utc_datetime_usec

    # Org
    belongs_to :org, Passwordless.Organizations.Org
    belongs_to :user, Passwordless.Accounts.User
    belongs_to :auth_token, Passwordless.AuthToken
    belongs_to :target_user, Passwordless.Accounts.User

    # App
    belongs_to :app, Passwordless.App

    # Email
    belongs_to :domain, Domain, type: :binary_id

    # Billing
    belongs_to :billing_customer, Passwordless.Billing.Customer
    belongs_to :billing_subscription, Passwordless.Billing.Subscription

    timestamps(updated_at: false)
  end

  def domain_action, do: @category_actions

  def full_recipient_parts(%__MODULE__{user: %User{name: name, email: email}}), do: {:user, name, email}

  def full_recipient_parts(%__MODULE__{}), do: {nil, nil, nil}

  @doc """
  Get by org.
  """
  def get_by_org(query \\ __MODULE__, %Org{} = org) do
    from q in query, where: q.org_id == ^org.id
  end

  @doc """
  Get by app.
  """
  def get_by_app(query \\ __MODULE__, %App{} = app) do
    from q in query, where: q.app_id == ^app.id
  end

  def get_within(query, %Date{} = start_date, %Date{} = end_date) do
    from q in query,
      where:
        fragment("?::date", q.happened_at) >= ^end_date and
          fragment("?::date", q.happened_at) <= ^start_date
  end

  @doc """
  Join the users.
  """
  def join_users(query \\ __MODULE__) do
    from q in query,
      join: u in assoc(q, :user),
      as: :user,
      preload: [user: u]
  end

  @doc """
  Join the orgs.
  """
  def join_orgs(query \\ __MODULE__) do
    from q in query,
      join: o in assoc(q, :org),
      as: :org
  end

  @doc """
  Select logs by action.
  """
  def by_action(query \\ __MODULE__, action)

  def by_action(query, action) when is_binary(action) do
    from q in query, where: q.action == ^action
  end

  def by_action(query, _action), do: query

  @doc """
  Select logs by user or target user.
  """
  def by_user(query \\ __MODULE__, %Accounts.User{id: user_id}) when is_binary(user_id) do
    from q in query, where: q.user_id == ^user_id or q.target_user_id == ^user_id
  end

  @doc """
  Select logs by author.
  """
  def by_author(query \\ __MODULE__, %Accounts.User{id: user_id}) do
    from q in query, where: q.user_id == ^user_id
  end

  @doc """
  Select logs for resources owned by the organization.
  """
  def by_org(query \\ __MODULE__, %Organizations.Org{id: org_id}) do
    from q in query, where: q.org_id == ^org_id
  end

  @doc """
  Preload associations.
  """
  def preload(query \\ __MODULE__, preloads) do
    from q in query, preload: ^preloads
  end

  @doc """
  Limit the number of logs.
  """
  def limit(query \\ __MODULE__, limit) do
    from q in query, limit: ^limit
  end

  @doc """
  Search the logs in unified manner.
  """
  def unified_search_filter(query, %Flop.Filter{value: value} = _flop_filter, _) do
    ActivityFilter.apply(query, value)
  end

  @fields ~w(
    action
    domain
    metadata
    happened_at
    org_id
    user_id
    auth_token_id
    target_user_id
    app_id
    billing_customer_id
    billing_subscription_id
    email_event_id
    email_message_id
    domain_id
  )a

  @required_fields ~w(
    action
    domain
    happened_at
  )a

  @doc """
  A log changeset to create a new log entry.
  """
  def changeset(%__MODULE__{} = log, attrs \\ %{}) do
    log
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_required_per_action()
    |> assoc_constraint(:org)
    |> assoc_constraint(:user)
    |> assoc_constraint(:auth_token)
    |> assoc_constraint(:target_user)
    |> assoc_constraint(:app)
    |> assoc_constraint(:email_event)
    |> assoc_constraint(:email_message)
    |> assoc_constraint(:domain)
  end

  @doc """
  Get all action names currently in use.
  """
  def supported_actions, do: @actions

  # Private

  defp validate_required_per_action(changeset) do
    case fetch_change(changeset, :action) do
      {:ok, action} when is_atom(action) ->
        {required, _acc} =
          Enum.flat_map_reduce(required_per_action(), nil, fn
            %{actions: [_ | _] = actions, required: [_ | _] = required}, acc ->
              {if(action in actions, do: required, else: []), acc}

            %{action_matcher: action_matcher, required: [_ | _] = required}, acc
            when is_function(action_matcher, 1) ->
              {if(action_matcher.(action), do: required, else: []), acc}

            _, acc ->
              {[], acc}
          end)

        validate_required(changeset, Enum.uniq(required))

      _ ->
        changeset
    end
  end

  defp required_per_action do
    [
      %{
        action_matcher: fn action ->
          String.starts_with?(Atom.to_string(action), "user.")
        end,
        required: ~w(
          user_id
        )a
      },
      %{
        actions: ~w(
          org.update_profile
          org.update_member
          org.delete_member
          org.create_invitation
          org.delete_invitation
          org.accept_invitation
          org.reject_invitation
        )a,
        required: ~w(
          org_id
          user_id
        )a
      },
      %{
        actions: ~w(
          org.create_auth_token
          org.update_auth_token
          org.revoke_auth_token
        )a,
        required: ~w(
          org_id
          user_id
          auth_token_id
        )a
      },
      %{
        action_matcher: fn action ->
          String.starts_with?(Atom.to_string(action), "subscription.")
        end,
        required: ~w(
          org_id
          billing_customer_id
          billing_subscription_id
        )a
      }
    ]
  end
end
