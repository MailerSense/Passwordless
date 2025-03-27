defmodule Passwordless.Accounts.Token do
  @moduledoc """
  A token is assigned to a user for a specific context (purpose).
  """

  use Passwordless.Schema, prefix: "acctkn"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Accounts.User
  alias PasswordlessWeb.Endpoint
  alias Phoenix.Token

  @size 32
  @lifetimes [
    session: :timer.hours(7 * 24),
    email_change: :timer.hours(6),
    email_confirmation: :timer.hours(6),
    password_reset: :timer.hours(6),
    passwordless_sign_in: :timer.minutes(30)
  ]
  @contexts Keyword.keys(@lifetimes)

  schema "user_tokens" do
    field :email, :string
    field :token, :binary
    field :context, Ecto.Enum, values: @contexts

    # Virtual
    field :name, :map, virtual: true

    belongs_to :user, User

    timestamps()
  end

  def contexts, do: @contexts

  @doc """
  Creates a new token for the given user and context.
  """
  def new(%User{} = user, context, attrs \\ %{}) when context in @contexts do
    {token, token_signed} = generate_token(context)

    params = Map.merge(attrs, %{token: token, context: context})

    changeset =
      user
      |> Ecto.build_assoc(:tokens)
      |> changeset(params)

    {token_signed, changeset}
  end

  def hash(%__MODULE__{token: token}), do: :crypto.hash(:sha256, token)

  @excluded_time_unites ~w(second seconds millisecond milliseconds)

  def readable_expiry_time(%__MODULE__{context: context, inserted_at: inserted_at}) do
    now = DateTime.utc_now()
    expires_at = Timex.shift(inserted_at, milliseconds: Keyword.fetch!(@lifetimes, context))

    now
    |> Timex.diff(expires_at, :seconds)
    |> Timex.Duration.from_seconds()
    |> Timex.Format.Duration.Formatters.Humanized.format()
    |> String.split(", ")
    |> Enum.reject(fn s -> Enum.any?(@excluded_time_unites, &String.ends_with?(s, &1)) end)
    |> Enum.join(", ")
  end

  def readable_name(%__MODULE__{context: context} = token) do
    "#{Phoenix.Naming.humanize(context)} (expires in #{readable_expiry_time(token)})"
  end

  @fields ~w(token email context user_id)a
  @required_fields ~w(token context user_id)a

  @doc """
  A user token changeset.
  """
  def changeset(%__MODULE__{} = token, attrs \\ %{}) do
    token
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_token()
    |> validate_email()
    |> assoc_constraint(:user)
  end

  @edit_fields ~w(email context user_id)a
  @edit_required_fields @edit_fields

  @doc """
  An edit user token changeset.
  """
  def edit_changeset(token, attrs \\ %{}, _metadata) do
    token
    |> cast(attrs, @edit_fields)
    |> validate_required(@edit_required_fields)
    |> validate_email()
    |> assoc_constraint(:user)
  end

  @doc """
  Query for getting user by token and context.
  """
  def get_user_by_token_and_context(token_signed, context) when is_binary(token_signed) and context in @contexts do
    with {:ok, token} <- verify_token(token_signed, context) do
      {:ok,
       from(t in __MODULE__,
         where:
           t.context == ^context and
             t.token == ^token and
             t.inserted_at > ago(^Keyword.fetch!(@lifetimes, context), "millisecond"),
         join: u in assoc(t, :user),
         select: u
       )}
    end
  end

  @doc """
  Query for getting token by user and token and context.
  """
  def get_by_user_and_token_and_context(%User{id: user_id}, token_signed, context)
      when is_binary(token_signed) and context in @contexts do
    with {:ok, token} <- verify_token(token_signed, context) do
      {:ok,
       from(t in __MODULE__,
         where:
           t.user_id == ^user_id and
             t.token == ^token and
             t.context == ^context and
             t.inserted_at > ago(^Keyword.fetch!(@lifetimes, context), "millisecond")
       )}
    end
  end

  @doc """
  Query for getting token by token and context.
  """
  def get_by_token_and_context(token_signed, context) when is_binary(token_signed) and context in @contexts do
    with {:ok, token} <- verify_token(token_signed, context) do
      {:ok, from(t in __MODULE__, where: t.token == ^token and t.context == ^context)}
    end
  end

  def get_tokens_by_user_and_context(%User{id: user_id}, context) when context in @contexts do
    from(t in __MODULE__,
      where:
        t.user_id == ^user_id and
          t.context == ^context and
          t.inserted_at > ago(^Keyword.fetch!(@lifetimes, context), "millisecond")
    )
  end

  # Private

  defp validate_token(changeset) do
    changeset
    |> validate_length(:token, is: @size, count: :bytes)
    |> unique_constraint(:token)
    |> unsafe_validate_unique(:token, Passwordless.Repo)
  end

  defp validate_email(changeset) do
    ChangesetExt.validate_email(changeset, :email)
  end

  defp generate_token(context) when context in @contexts do
    raw = :crypto.strong_rand_bytes(@size)
    signed = Token.sign(Endpoint, token_salt(), raw)
    {raw, signed}
  end

  defp verify_token(token, context) when is_binary(token) and context in @contexts do
    Token.verify(Endpoint, token_salt(), token, max_age: div(Keyword.fetch!(@lifetimes, context), 1000))
  end

  defp token_salt, do: Endpoint.config(:secret_key_base)
end
