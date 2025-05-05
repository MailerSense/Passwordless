defmodule Passwordless.Accounts.User do
  @moduledoc """
  A user is a person or service who can log in and interact with the system.
  """

  use Passwordless.Schema, prefix: "accuser"

  alias Database.ChangesetExt
  alias Passwordless.Accounts.Credential
  alias Passwordless.Accounts.OTP
  alias Passwordless.Accounts.Token
  alias Passwordless.Accounts.TOTP
  alias Passwordless.Organizations.Invitation
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org

  @states ~w(active locked)a
  @login_methods ~w(email_otp password)a

  schema "users" do
    field :name, :string
    field :email, :string
    field :state, Ecto.Enum, values: @states, default: :active
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime_usec
    field :company, :string, virtual: true
    field :login_method, Ecto.Enum, values: @login_methods, default: :email_otp, virtual: true
    field :terms_accepted, :boolean, virtual: true, default: false
    field :use_password, :boolean, virtual: true, default: false

    # Virtuals
    field :role, :any, virtual: true
    field :full_name, :string, virtual: true
    field :current_org, :map, virtual: true
    field :current_app, :map, virtual: true
    field :current_membership, :map, virtual: true
    field :current_impersonator, :map, virtual: true
    field :two_factor_enabled, :boolean, virtual: true, default: false
    field :is_online, :boolean, virtual: true, default: false

    has_one :otp, OTP
    has_one :totp, TOTP

    has_many :tokens, Token, preload_order: [asc: :inserted_at]
    has_many :credentials, Credential, preload_order: [asc: :inserted_at]
    has_many :invitations, Invitation, preload_order: [asc: :inserted_at]
    has_many :memberships, Membership, preload_order: [asc: :inserted_at]

    many_to_many :orgs, Org, join_through: Membership, unique: true

    timestamps()
    soft_delete_timestamp()
  end

  def states, do: @states

  def admin?(%__MODULE__{current_org: %Org{} = org, current_membership: %Membership{} = membership} = user) do
    active?(user) and
      confirmed?(user) and
      Org.admin?(org) and
      Membership.at_least?(membership, :admin)
  end

  def admin?(%__MODULE__{}), do: false

  @fields ~w(
    name
    email
    state
  )a
  @required_fields @fields

  @doc """
  A user changeset.
  """
  def changeset(user, attrs \\ %{}, _opts \\ []) do
    user
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_email()
    |> validate_state()
  end

  @create_fields ~w(
    name
    email
    state
    password
  )a
  @create_required_fields @create_fields

  @doc """
  A user create changeset.
  """
  def create_changeset(user, attrs \\ %{}, _metadata \\ []) do
    user
    |> cast(attrs, @create_fields)
    |> validate_required(@create_required_fields)
    |> validate_name()
    |> validate_email()
    |> validate_state()
    |> validate_password()
  end

  @password_registration_fields ~w(
    name
    email
    company
    password
  )a
  @password_registration_required_fields @password_registration_fields -- [:company]

  @doc """
  A user changeset for registration.
  """
  def password_registration_changeset(%__MODULE__{} = user, attrs \\ %{}, opts \\ []) do
    user
    |> cast(attrs, @password_registration_fields)
    |> validate_required(@password_registration_required_fields)
    |> validate_name()
    |> validate_email()
    |> validate_state()
    |> validate_password(opts)
  end

  @internal_registration_fields ~w(
    name
    email
    company
    login_method
    terms_accepted
  )a
  @internal_registration_required_fields @internal_registration_fields

  @doc """
  A user changeset for internal registration.
  """
  def internal_registration_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, @internal_registration_fields)
    |> validate_required(@internal_registration_required_fields)
    |> validate_name()
    |> validate_email()
    |> validate_state()
    |> validate_company()
  end

  @external_registration_fields ~w(
    name
    email
  )a
  @external_registration_required_fields @external_registration_fields

  @doc """
  A user changeset for registration via external provider e.g. social.
  """
  def external_registration_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, @external_registration_fields)
    |> validate_required(@external_registration_required_fields)
    |> validate_name()
    |> validate_email()
    |> validate_state()
  end

  @doc """
  A user changeset for passwordless registration.
  """
  def passwordless_registration_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    %__MODULE__{user | state: :locked}
    |> cast(attrs, [:email])
    |> validate_email()
    |> validate_state()
  end

  @doc """
  A user changeset for updating the users's state.
  """
  def state_changeset(%__MODULE__{} = user, params \\ %{}) do
    user
    |> cast(params, [:state])
    |> validate_state()
  end

  @doc "A changeset for users changing their details. Keep this limited to what A user can change about themselves."
  def profile_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name])
    |> validate_name()
  end

  @doc """
  Confirms the user by setting `confirmed_at`.
  """
  def confirmation_changeset(%__MODULE__{} = user) do
    change(user, confirmed_at: DateTime.utc_now())
  end

  @doc """
  A user changeset for changing the email.
  """
  def email_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "please enter a different email address")
    end
  end

  @doc """
  A user changeset for changing the email naively.
  """
  def naive_email_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:email, :login_method, :use_password])
    |> ChangesetExt.validate_email()
  end

  @doc """
  A user credential changeset for changing the password.
  """
  def password_changeset(%__MODULE__{} = user, attrs \\ %{}, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  A user credential changeset for changing the password.
  """
  def naive_current_password_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:current_password])
    |> validate_password(field: :current_password, hash_password: false)
  end

  @doc """
  A user credential changeset for changing the password along with validating the current one.
  """
  def current_password_changeset(%__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:password, :current_password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(hash_password: false)
    |> validate_password(field: :current_password, hash_password: false)
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password, safe: true) do
      changeset
    else
      add_error(changeset, :current_password, "does not match your account password")
    end
  end

  @doc """
  Compares the given password with the stored password hash.
  """
  def valid_password?(user, password, opts \\ [])

  def valid_password?(%__MODULE__{password_hash: password_hash}, password, _opts)
      when is_binary(password_hash) and byte_size(password) > 0 do
    Argon2.verify_pass(password, password_hash)
  end

  def valid_password?(%__MODULE__{}, _, opts) do
    unless Keyword.get(opts, :safe, false) do
      Argon2.no_user_verify()
    end

    false
  end

  @doc """
  Is the user active?
  """
  def active?(%__MODULE__{state: :active}), do: true
  def active?(%__MODULE__{}), do: false

  @doc """
  Is the user confirmed?
  """
  def confirmed?(%__MODULE__{confirmed_at: %DateTime{}}), do: true
  def confirmed?(%__MODULE__{}), do: false
  def confirmed?(_), do: false

  @doc """
  Does the user have a password?
  """
  def has_password?(%__MODULE__{password_hash: password_hash}) when is_binary(password_hash), do: true

  def has_password?(%__MODULE__{}), do: false

  # Private

  defp validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 255)
  end

  defp validate_state(changeset) do
    ChangesetExt.validate_state(changeset,
      locked: [:active],
      active: [:locked]
    )
  end

  defp validate_email(changeset) do
    changeset
    |> ChangesetExt.validate_email()
    |> unique_constraint(:email)
    |> unsafe_validate_unique(:email, Passwordless.Repo)
  end

  defp validate_company(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:company)
    |> validate_length(:company, min: 1, max: 255)
  end

  defp validate_password(changeset, opts \\ []) do
    field = Keyword.get(opts || [], :field, :password)

    changeset
    |> validate_required([field])
    |> validate_length(field, min: 8, max: 72)
    |> validate_format(field, ~r/[a-z]/, message: "at least 1 lower case letter")
    |> validate_format(field, ~r/[A-Z]/, message: "at least 1 upper case letter")
    |> validate_format(field, ~r/[!?@#$%^&*_0-9]/, message: "at least 1 digit or special symbol")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts || [], :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:password_hash, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
