defmodule Passwordless.Challenge do
  @moduledoc false

  use Passwordless.Schema, prefix: "chlng"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.Action
  alias Passwordless.EmailMessage

  @state_machines [
    email_otp: [
      otp_sent: [:otp_sent, :otp_validated]
    ],
    sms_otp: [
      otp_sent: [:otp_sent, :otp_validated]
    ],
    whatsapp_otp: [
      otp_sent: [:otp_sent, :otp_validated]
    ],
    magic_link: [
      magic_link_sent: [:magic_link_sent, :magic_link_validated]
    ]
  ]

  @flows Keyword.keys(@state_machines)
  @states @state_machines
          |> Keyword.values()
          |> Enum.flat_map(&Enum.flat_map(&1, fn {s, f} -> [s | f] end))
          |> Enum.uniq()

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "challenges" do
    field :flow, Ecto.Enum, values: @flows
    field :state, Ecto.Enum, values: @states
    field :current, :boolean, default: false

    has_one :email_message, EmailMessage, where: [current: true]

    has_many :email_messages, EmailMessage

    belongs_to :action, Action

    timestamps()
  end

  def flows, do: @flows
  def states, do: @states

  @fields ~w(
    flow
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
    with {_, flow} <- fetch_field(changeset, :flow),
         {:ok, machine} <- Keyword.fetch(@state_machines, flow) do
      ChangesetExt.validate_state(changeset, machine)
    else
      _ -> add_error(changeset, :state, "state machine for flow not found")
    end
  end
end
