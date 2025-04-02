defmodule Passwordless.Challenge do
  @moduledoc false

  use Passwordless.Schema, prefix: "chlng"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Action
  alias Passwordless.EmailMessage

  @typedoc """
  The authenticator that can be used to authenticate the user.
  """
  @type authenticator ::
          Passwordless.Authenticators.Email.t()
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
              actor :: Passwordless.Actor.t(),
              action :: Passwordless.Action.t(),
              event: atom(),
              attrs: handle_attrs()
            ) :: {:ok, Passwordless.Action.t()} | {:error, atom()}

  @state_machines [
    email_otp: [
      started: [:otp_sent],
      otp_sent: [:otp_sent, :otp_validated]
    ],
    sms_otp: [
      started: [:otp_sent],
      otp_sent: [:otp_sent, :otp_validated]
    ],
    whatsapp_otp: [
      started: [:otp_sent],
      otp_sent: [:otp_sent, :otp_validated]
    ],
    magic_link: [
      started: [:magic_link_sent],
      magic_link_sent: [:magic_link_sent, :magic_link_validated]
    ],
    password: [
      started: [:password_validated]
    ]
  ]
  @end_states [
    :otp_validated,
    :magic_link_validated,
    :password_validated
  ]

  @types Keyword.keys(@state_machines)
  @states @state_machines
          |> Keyword.values()
          |> Enum.flat_map(&Enum.flat_map(&1, fn {s, f} -> [s | f] end))
          |> Enum.uniq()

  @derive {Jason.Encoder,
           only: [
             :id,
             :type,
             :state,
             :current,
             :email_message,
             :email_messages,
             :inserted_at,
             :updated_at
           ]}
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "challenges" do
    field :type, Ecto.Enum, values: @types
    field :state, Ecto.Enum, values: @states
    field :current, :boolean, default: false

    has_one :email_message, EmailMessage, where: [current: true]

    has_many :email_messages, EmailMessage, preload_order: [asc: :inserted_at]

    belongs_to :action, Action

    timestamps()
  end

  def types, do: @types
  def states, do: @states

  def validated?(%__MODULE__{state: state}) when state in @end_states, do: true
  def validated?(_), do: false

  @fields ~w(
    type
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
    with {_, type} <- fetch_field(changeset, :type),
         {:ok, machine} <- Keyword.fetch(@state_machines, type) do
      ChangesetExt.validate_state(changeset, machine)
    else
      _ -> add_error(changeset, :state, "state machine for type not found")
    end
  end
end
