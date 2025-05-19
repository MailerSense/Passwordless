defmodule Passwordless.Challenge do
  @moduledoc false

  use Passwordless.Schema, prefix: "chlng"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Action
  alias Passwordless.ChallengeToken
  alias Passwordless.EmailMessage

  @typedoc """
  The authenticator that can be used to authenticate the user.
  """
  @type authenticator ::
          Passwordless.Authenticators.EmailOTP.t()
          | Passwordless.Authenticators.SMS.t()
          | Passwordless.Authenticators.WhatsApp.t()
          | Passwordless.Authenticators.MagicLink.t()
          | Passwordless.Authenticators.TOTP.t()
          | Passwordless.Authenticators.RecoveryCodes.t()

  @typedoc """
  The attributes that can be passed to the handle function.
  """
  @type handle_attrs :: %{
          optional(:code) => String.t(),
          optional(:token) => String.t(),
          optional(:email) => Passwordless.Email.t(),
          optional(:phone) => Passwordless.Phone.t(),
          optional(:authenticator) => authenticator()
        }

  @doc """
  Handle the authentication challenge.
  """
  @callback handle(
              app :: Passwordless.App.t(),
              user :: Passwordless.User.t(),
              action :: Passwordless.Action.t(),
              event: binary(),
              attrs: handle_attrs()
            ) :: {:ok, Passwordless.Action.t()} | {:error, atom()}

  @state_machines [
    email_otp: [
      started: [:otp_sent],
      otp_sent: [:otp_sent, :otp_validated, :otp_invalid],
      otp_invalid: [:otp_validated]
    ],
    magic_link: [
      started: [:magic_link_sent],
      magic_link_sent: [:magic_link_sent, :magic_link_validated]
    ],
    totp: [
      started: [:totp_validated]
    ],
    recovery_codes: [
      started: [:recovery_code_accepted]
    ],
    password: [
      started: [:password_validated]
    ]
  ]
  @starting_states Keyword.new(@state_machines, fn {machine, [{state, _trans} | _]} -> {machine, state} end)
  @end_states [
    :otp_validated,
    :magic_link_validated,
    :password_validated
  ]
  @kinds Keyword.keys(@state_machines)
  @states @state_machines
          |> Keyword.values()
          |> Enum.flat_map(&Enum.flat_map(&1, fn {s, f} -> [s | f] end))
          |> Enum.uniq()

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :kind,
      :state,
      :options,
      :email_message,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "challenges" do
    field :kind, Ecto.Enum, values: @kinds
    field :state, Ecto.Enum, values: @states
    field :current, :boolean, default: false

    embeds_many :options, Option, on_replace: :delete, primary_key: false do
      @derive Jason.Encoder

      field :name, :string, primary_key: true
      field :info, :map, default: %{}
    end

    has_one :email_message, EmailMessage, where: [current: true]
    has_one :challenge_token, ChallengeToken

    has_many :email_messages, EmailMessage, preload_order: [asc: :inserted_at]

    belongs_to :action, Action

    timestamps()
  end

  def kinds, do: @kinds
  def states, do: @states
  def starting_state!(machine), do: Keyword.fetch!(@starting_states, machine)

  def validated?(%__MODULE__{state: state}) when state in @end_states, do: true
  def validated?(_), do: false

  @fields ~w(
    kind
    state
    current
    action_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = challenge, attrs \\ %{}, opts \\ []) do
    challenge
    |> cast(attrs, @fields)
    |> cast_embed(:options, with: &option_changeset/2)
    |> validate_required(@required_fields)
    |> validate_state()
    |> assoc_constraint(:action)
    |> unique_constraint([:action_id, :current], error_key: :current)
    |> unsafe_validate_unique([:action_id, :current], Passwordless.Repo,
      query: from(c in __MODULE__, where: c.current),
      prefix: Keyword.get(opts, :prefix),
      error_key: :current
    )
  end

  @doc """
  A state changeset.
  """
  def state_changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, [:state])
    |> validate_required([:state])
    |> validate_state()
  end

  # Private

  defp validate_state(changeset) do
    with {_, kind} <- fetch_field(changeset, :kind),
         {:ok, machine} <- Keyword.fetch(@state_machines, kind) do
      ChangesetExt.validate_state(changeset, machine)
    else
      _ -> add_error(changeset, :state, "state machine for kind not found")
    end
  end

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> validate_length(field, min: 1, max: 255)
  end

  defp option_changeset(%__MODULE__.Option{} = option, attrs) do
    option
    |> cast(attrs, [:name, :info])
    |> validate_required([:name, :info])
    |> validate_string(:name)
    |> ChangesetExt.validate_property_map(:info)
  end
end
