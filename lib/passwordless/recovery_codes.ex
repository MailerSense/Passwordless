defmodule Passwordless.RecoveryCodes do
  @moduledoc false

  use Passwordless.Schema, prefix: "reccodes"

  alias Passwordless.Actor

  @derive {Jason.Encoder,
           only: [
             :id,
             :inserted_at,
             :updated_at,
             :deleted_at
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "recovery_codes" do
    embeds_many :codes, Code, on_replace: :delete do
      @derive {Jason.Encoder, only: [:used_at]}

      field :code, :string, redact: true
      field :used_at, :utc_datetime_usec
    end

    belongs_to :actor, Actor

    timestamps()
    soft_delete_timestamp()
  end

  @doc """
  Validates the TOTP backup code and updates the used_at field if the code is valid.
  """
  def validate_backup_code(%__MODULE__{} = recovery_codes, code) when is_binary(code) do
    recovery_codes.codes
    |> Enum.map_reduce(false, fn %__MODULE__.Code{} = backup, valid? ->
      if Plug.Crypto.secure_compare(backup.code, code) and is_nil(backup.used_at) do
        {change(backup, %{used_at: DateTime.utc_now()}), true}
      else
        {backup, valid?}
      end
    end)
    |> case do
      {codes, true} ->
        recovery_codes
        |> change()
        |> put_embed(:codes, codes)

      {_, false} ->
        nil
    end
  end

  def validate_codes(%__MODULE__{}, _code), do: nil

  def regenerate_codes(changeset) do
    put_embed(changeset, :codes, generate_codes())
  end

  def changeset(%__MODULE__{} = recovery_codes, opts \\ []) do
    recovery_codes
    |> change()
    |> ensure_codes()
    |> assoc_constraint(:actor)
    |> unique_constraint(:actor_id)
    |> unsafe_validate_unique(:actor_id, Passwordless.Repo, prefix: Keyword.get(opts, :prefix))
  end

  def ensure_codes(changeset) do
    case get_field(changeset, :codes) do
      [] -> regenerate_codes(changeset)
      _ -> changeset
    end
  end

  # Private

  defp generate_codes do
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
      %__MODULE__.Code{code: code}
    end
  end
end
