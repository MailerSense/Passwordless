defmodule Passwordless.Accounts.TOTP do
  @moduledoc """
  Defines two factor strategies for accounts
  """

  use Passwordless.Schema

  import Ecto.Query, warn: false

  alias Passwordless.Accounts.User

  schema "user_totps" do
    field :secret, :binary
    field :code, :string, virtual: true

    embeds_many :backup_codes, BackupCode, on_replace: :delete do
      field :code, :string
      field :used_at, :utc_datetime_usec
    end

    belongs_to :user, User, type: :binary_id

    timestamps()
  end

  @doc """
  A user second factor changeset.
  """
  def changeset(%__MODULE__{} = totp, params \\ %{}) do
    changeset =
      totp
      |> cast(params, [:secret, :code, :user_id])
      |> validate_required([:code, :secret])
      |> validate_format(:code, ~r/^\d{6}$/, message: "should be a 6 digit number")
      |> assoc_constraint(:user)

    validate_change(changeset, :code, fn :code, code ->
      with {_, secret} when is_binary(secret) <- fetch_field(changeset, :secret),
           true <- NimbleTOTP.valid?(secret, code) do
        []
      else
        _ -> [code: "is invalid"]
      end
    end)
  end

  # TOTP

  @doc """
  Check if a TOTP code is valid.
  """
  def valid_totp?(%__MODULE__{secret: secret}, code) when is_binary(code) and byte_size(code) == 6,
    do: NimbleTOTP.valid?(secret, code)

  def valid_totp?(%__MODULE__{}, _code), do: false

  @doc """
  Validates the TOTP backup code and updates the used_at field if the code is valid.
  """
  def validate_backup_code(%__MODULE__{} = totp, code) when is_binary(code) do
    totp.backup_codes
    |> Enum.map_reduce(false, fn %__MODULE__.BackupCode{} = backup, valid? ->
      if Plug.Crypto.secure_compare(backup.code, code) and is_nil(backup.used_at) do
        {change(backup, %{used_at: DateTime.utc_now()}), true}
      else
        {backup, valid?}
      end
    end)
    |> case do
      {backup_codes, true} ->
        totp
        |> change()
        |> put_embed(:backup_codes, backup_codes)

      {_, false} ->
        nil
    end
  end

  def validate_backup_codes(%__MODULE__{}, _code), do: nil

  def regenerate_backup_codes(changeset) do
    put_embed(changeset, :backup_codes, generate_backup_codes())
  end

  def ensure_backup_codes(changeset) do
    case get_field(changeset, :backup_codes) do
      [] -> regenerate_backup_codes(changeset)
      _ -> changeset
    end
  end

  # Private

  defp generate_backup_codes do
    for letter <- Enum.take_random(?A..?Z, 10) do
      suffix =
        5
        |> :crypto.strong_rand_bytes()
        |> Base.encode32()
        |> binary_part(0, 7)

      # The first digit is always a letter so we can distinguish
      # in the UI between 6 digit TOTP codes and backup ones.
      # We also replace the letter O by X to avoid confusion with zero.
      code = String.replace(<<letter, suffix::binary>>, "O", "X")
      %__MODULE__.BackupCode{code: code}
    end
  end
end
