defmodule Passwordless.TOTP do
  @moduledoc """
  Defines two factor strategies for actors
  """

  use Passwordless.Schema, prefix: "totp"

  alias Passwordless.Actor

  schema "totps" do
    field :name, :string
    field :secret, :binary, redact: true
    field :code, :string, virtual: true

    belongs_to :actor, Actor

    timestamps()
  end

  @fields ~w(
    name
    secret
    actor_id
  )a
  @required_fields @fields

  @doc """
  A user second factor changeset.
  """
  def changeset(%__MODULE__{} = totp, params \\ %{}) do
    changeset =
      totp
      |> cast(params, @fields)
      |> validate_required(@required_fields)
      |> validate_format(:code, ~r/^\d{6}$/, message: "should be a 6 digit number")
      |> assoc_constraint(:actor)

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
end
