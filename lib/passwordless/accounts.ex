defmodule Passwordless.Accounts do
  @moduledoc """
  The Account context.
  """

  alias Passwordless.Accounts.Credential
  alias Passwordless.Accounts.Notifier
  alias Passwordless.Accounts.Token
  alias Passwordless.Accounts.TOTP
  alias Passwordless.Accounts.User
  alias Passwordless.Activity
  alias Passwordless.Repo

  require Logger

  ## Database getters

  @doc """
  Gets a single user.
  """

  def get_user(id) when is_binary(id), do: Repo.get(User, id)
  def get_user(_id), do: nil

  @doc """
  Gets a single user.
  """

  def get_user!(id) when is_binary(id), do: Repo.get!(User, id)
  def get_user!(_id), do: nil

  @doc """
  Returns a list of all users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: Util.trim_downcase(email))
  end

  def get_user_by_email(_email), do: nil

  @doc """
  Gets a user by email and password.
  """
  def get_user_by_email_and_password(email, password) when is_binary(email) and is_binary(password) do
    with %User{} = user <- get_user_by_email(email),
         true <- User.valid_password?(user, password),
         do: user
  end

  ## User registration

  @doc """
  Inserts a new user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Attempts to get gets a user by email. If the user is not found, register a new user.
  """
  def get_or_register_user(email, attrs \\ %{}, opts \\ [])

  def get_or_register_user(email, attrs, opts) when is_binary(email) do
    case get_user_by_email(email) do
      %User{} = user -> {:ok, user}
      _ -> register_user(Map.put(attrs, :email, email), opts)
    end
  end

  def get_or_register_user(_email, _attrs, _opts), do: {:error, :invalid_email}

  @doc """
  Registers a user.
  """
  def register_user(attrs, opts \\ []) when is_map(attrs) do
    {via, opts} = Keyword.pop(opts, :via, :password)

    multi =
      case via do
        :password ->
          Ecto.Multi.insert(Ecto.Multi.new(), :user, User.registration_changeset(%User{}, attrs))

        :passwordless ->
          Ecto.Multi.insert(Ecto.Multi.new(), :user, User.passwordless_registration_changeset(%User{}, attrs))

        :external_provider ->
          Ecto.Multi.new()
          |> Ecto.Multi.insert(:user, User.external_registration_changeset(%User{}, attrs))
          |> Ecto.Multi.insert(:credential, fn %{user: %User{} = user} ->
            user
            |> Ecto.build_assoc(:credentials)
            |> Credential.changeset(opts |> Keyword.take([:subject, :provider]) |> Map.new())
          end)
      end

    case Repo.transaction(multi) do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}

      {:error, :credential, _changeset, _} ->
        {:error, :credential_failed}
    end
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs \\ %{}) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user.
  """
  def change_user(user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Emulates that the e-mail will change without actually changing
  it in the database. Used for email changes and no passwords.
  """
  def can_change_user_email?(%User{} = user, attrs \\ %{}) do
    user
    |> User.email_changeset(attrs)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.
  """
  def change_user_email(%User{} = user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.
  """
  def apply_user_email(%User{} = user, attrs \\ %{}) do
    user
    |> User.email_changeset(attrs)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.
  """
  def update_user_email(%User{} = user, token) do
    context = :email_change

    with {:ok, query} <- Token.get_by_user_and_token_and_context(user, token, context),
         %Token{context: ^context, email: email} <- Repo.one(query),
         {:ok, %{user: updated_user}} <- Repo.transaction(update_email_multi(user, email, context)),
         do: {:ok, updated_user}
  end

  @doc """
  Delivers the update email instructions to the given User.
  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_binary(current_email) and is_function(update_email_url_fun, 1) do
    {token_signed, token} = Token.new(user, :email_change, %{email: current_email})
    Repo.insert!(token)
    Notifier.deliver_update_email_instructions(user, update_email_url_fun.(token_signed))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.
  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.
  """
  def update_user_password(%User{} = user, password, attrs \\ %{}) when is_binary(password) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, Token.get_tokens_by_user_and_context(user, :password_reset))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def update_user_profile(%User{} = user, attrs \\ %{}) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  ## State

  def activate_user!(%User{state: :locked} = user) do
    user =
      user
      |> User.state_changeset(%{state: :active})
      |> Repo.update!()

    Activity.log_async(:"user.activate", %{user: user})

    user
  end

  def activate_user!(%User{} = user), do: user

  def unlock_user(%User{} = user) do
    user =
      user
      |> User.state_changeset(%{state: :active})
      |> Repo.update()

    Activity.log_async(:"user.unlock", %{user: user})

    user
  end

  def lock_user(%User{} = user) do
    user =
      user
      |> User.state_changeset(%{state: :locked})
      |> Repo.update()

    Activity.log_async(:"user.lock", %{user: user})

    user
  end

  def preload_user_memberships(%User{} = user) do
    Repo.preload(user, memberships: :org)
  end

  ## Token

  @doc """
  Gets the user by token and context.
  """
  def get_user_by_token(token, context) when is_binary(token) and is_atom(context) do
    case Token.get_user_by_token_and_context(token, context) do
      {:ok, query} -> Repo.one(query)
      _ -> nil
    end
  end

  def get_user_by_token(_token, _context), do: nil

  @doc """
  Deletes the session token with the given context.
  """
  def delete_user_token(%User{} = user, token, context) do
    with {:ok, query} <- Token.get_by_user_and_token_and_context(user, token, context) do
      Repo.delete_all(query)
    end

    :ok
  end

  ## Session

  @doc """
  Generates a session token for the given User.
  """
  def generate_user_session_token!(%User{} = user) do
    {token_signed, token} = Token.new(user, :session)
    {token_signed, Repo.insert!(token)}
  end

  @doc """
  Gets the user with the given session token.
  """
  def get_user_by_session_token(token) when is_binary(token) do
    get_user_by_token(token, :session)
  end

  @doc """
  Deletes the session token with the given context.
  """
  def delete_user_session_token(%Token{} = token) do
    Repo.delete!(token)
    :ok
  end

  def delete_user_session_token(token) when is_binary(token) do
    with {:ok, query} <- Token.get_by_token_and_context(token, :session) do
      Repo.delete_all(query)
    end

    :ok
  end

  @doc """
  Gets all session tokens for the given user.
  """
  def get_user_session_tokens(%User{} = user) do
    Repo.all(Token.get_tokens_by_user_and_context(user, :session))
  end

  ## Onboarding

  @doc """
  Checks if the user needs onboarding.
  """
  def user_needs_onboarding?(%User{name: nil}), do: {:yes, :user}

  def user_needs_onboarding?(%User{} = user) do
    user = Repo.preload(user, [{:invitations, :org}, :memberships])

    cond do
      # We have outstanding invitation(s), so
      # ask the user to join one of these organizations.
      Enum.empty?(user.memberships) and not Enum.empty?(user.invitations) -> {:yes, {:org_invitation, user.invitations}}
      # We have no outstanding invitation(s), so
      # ask the user to create their own organization.
      Enum.empty?(user.memberships) -> {:yes, :org}
      # We're good to go
      true -> :no
    end
  end

  ## Confirmation

  @doc """
  Confirms a user without checking any tokens
  """
  def confirm_user!(%User{} = user) do
    if User.confirmed?(user) do
      user
    else
      {:ok, %{user: confirmed_user}} = Repo.transaction(confirm_user_multi(user))
      confirmed_user
    end
  end

  @doc """
  Confirms a user by the given token.
  """
  def confirm_user_by_token(token) when is_binary(token) do
    with %User{} = user <- get_user_by_token(token, :email_confirmation),
         {:ok, %{user: confirmed_user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, confirmed_user}
    else
      _ -> :error
    end
  end

  @doc """
  Delivers the confirmation email instructions to the given User.
  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if User.confirmed?(user) do
      {:error, :already_confirmed}
    else
      {token_signed, token} = Token.new(user, :email_confirmation)
      Repo.insert!(token)
      url = confirmation_url_fun.(token_signed)

      if Passwordless.config(:env) == :dev do
        Logger.info("--- Confirmation URL: #{url}")
      end

      Notifier.deliver_confirmation_instructions(user, url)
    end
  end

  ## Reset password

  @doc """
  Gets the user by reset password token.
  """
  def get_user_by_reset_password_token(token) when is_binary(token) do
    get_user_by_token(token, :password_reset)
  end

  @doc """
  Resets the user password.
  """
  def reset_user_password(%User{} = user, attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, Token.get_tokens_by_user_and_context(user, :password_reset))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Returns a User changeset that is valid if the current password is valid.

  It returns a changeset. The changeset has an action if the current password
  is not nil.
  """
  def validate_user_current_password(%User{} = user, current_password) do
    user
    |> Ecto.Changeset.change()
    |> User.validate_current_password(current_password)
    |> attach_action_if_current_password(current_password)
  end

  @doc """
  Delivers the reset password email to the given User.
  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {token_signed, token} = Token.new(user, :password_reset)

    with {:ok, _token} <- Repo.insert(token) do
      Notifier.deliver_reset_password_instructions(user, reset_password_url_fun.(token_signed))
    end
  end

  ## Passwordless

  @doc """
  Generates a passwordless sign in token for the given User.
  """
  def generate_user_passwordless_token(%User{} = user) do
    context = :passwordless_sign_in

    Repo.transact(fn ->
      Repo.delete_all(Token.get_tokens_by_user_and_context(user, context))
      {token_signed, token} = Token.new(user, context)

      with {:ok, _token} <- Repo.insert(token) do
        {:ok, token_signed}
      end
    end)
  end

  @doc """
  Gets the user by passwordless sign in token.
  """
  def get_user_by_passwordless_token(token) do
    get_user_by_token(token, :passwordless_sign_in)
  end

  @doc """
  Generates a temporary token for the given User.
  """
  def generate_user_temporary_token(%User{id: user_id}) do
    token = Util.random_string()
    Passwordless.Cache.put(token, user_id, ttl: :timer.minutes(5))
    token
  end

  @doc """
  Fetches user by temporary token.
  """
  def get_user_by_temporary_token!(token) do
    get_user!(Passwordless.Cache.get(token))
  end

  @doc """
  Delivers the magic link to the given User.
  """
  def deliver_magic_link(%User{} = user, magic_link_url_fun) when is_function(magic_link_url_fun, 1) do
    context = :passwordless_sign_in

    Repo.delete_all(Token.get_tokens_by_user_and_context(user, context))

    {token_signed, token} = Token.new(user, context)

    with {:ok, _token} <- Repo.insert(token) do
      Notifier.deliver_passwordless_token(user, magic_link_url_fun.(token_signed))
    end
  end

  ## 2FA / TOTP (Time based One Time Password)

  def two_factor_auth_enabled?(%User{} = user) do
    !!get_user_totp(user)
  end

  @doc """
  Gets the %UserTOTP{} entry, if any.
  """
  def get_user_totp(%User{} = user) do
    Repo.get_by(TOTP, user_id: user.id)
  end

  @doc """
  Deletes the second factor.
  """
  def delete_user_totp(%TOTP{} = totp) do
    Repo.delete!(totp)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing user TOTP.
  """
  def change_user_totp(%TOTP{} = totp, attrs \\ %{}) do
    TOTP.changeset(totp, attrs)
  end

  @doc """
  Updates the TOTP secret.

  The secret is a random 20 bytes binary that is used to generate the QR Code to
  enable 2FA using auth applications. It will only be updated if the OTP code
  sent is valid.
  """
  def upsert_user_totp(%TOTP{secret: secret} = totp, attrs \\ %{}) do
    changeset =
      totp
      |> TOTP.changeset(attrs)
      |> TOTP.ensure_backup_codes()
      |> Ecto.Changeset.force_change(:secret, secret)

    Repo.insert_or_update(changeset)
  end

  @doc """
  Regenerates the user backup codes for totp.
  """
  def regenerate_user_totp_backup_codes(%TOTP{} = totp) do
    totp
    |> Ecto.Changeset.change()
    |> TOTP.regenerate_backup_codes()
    |> Repo.update()
  end

  @doc """
  Validates if the given TOTP code is valid.
  """
  def validate_user_totp(%User{} = user, code) when is_binary(code) do
    totp = Repo.get_by!(TOTP, user_id: user.id)

    cond do
      TOTP.valid_totp?(totp, code) ->
        :valid_totp

      changeset = TOTP.validate_backup_code(totp, code) ->
        totp = Repo.update!(changeset)
        {:valid_backup_code, Enum.count(totp.backup_codes, &is_nil(&1.used_at))}

      true ->
        :invalid
    end
  end

  def validate_user_totp(%User{}, _code), do: :invalid

  # Private

  defp update_email_multi(%User{} = user, email, context) when is_binary(email) and is_atom(context) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.email_changeset(user, %{email: email}))
    |> Ecto.Multi.delete_all(:tokens, Token.get_tokens_by_user_and_context(user, context))
  end

  defp confirm_user_multi(%User{} = user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirmation_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, Token.get_tokens_by_user_and_context(user, :email_confirmation))
  end

  defp attach_action_if_current_password(changeset, nil), do: changeset

  defp attach_action_if_current_password(changeset, _), do: Map.replace!(changeset, :action, :validate)
end
