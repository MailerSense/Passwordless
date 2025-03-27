defmodule Passwordless.ActionEvent do
  @moduledoc """
  An action avent.
  """

  use Passwordless.Schema, prefix: "aevnt"

  alias Database.ChangesetExt
  alias Passwordless.Action

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "action_events" do
    field :flow, :string
    field :event, :string
    field :from_state, :string
    field :to_state, :string
    field :metadata, :map, default: %{}

    # User
    field :user_agent, :string
    field :ip_address, :string
    field :country, :string
    field :city, :string

    belongs_to :action, Action

    timestamps(updated_at: false)
  end

  @fields ~w(
    flow
    event
    from_state
    to_state
    metadata
    user_agent
    ip_address
    country
    city
    action_id
  )a
  @required_fields ~w(
    flow
    event
    from_state
    to_state
    metadata
    action_id
  )a

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = action, attrs \\ %{}) do
    action
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_ip_address()
    |> validate_user_agent()
    |> validate_string(:country)
    |> validate_string(:city)
    |> assoc_constraint(:action)
    |> assoc_constraint(:email_message)
  end

  # Private

  defp validate_string(changeset, field) do
    changeset
    |> ChangesetExt.ensure_trimmed(field)
    |> validate_length(field, min: 1, max: 255)
  end

  defp validate_ip_address(%Ecto.Changeset{valid?: true} = changeset) do
    with {_, raw_ip} <- fetch_field(changeset, :ip_address),
         {:ok, ip_address} <- InetCidr.parse_address(raw_ip),
         true <- is_public_ip(ip_address) do
      put_change(changeset, :ip_address, to_string(:inet.ntoa(ip_address)))
    else
      _ -> delete_change(changeset, :ip_address)
    end
  end

  defp validate_ip_address(changeset), do: changeset

  defp validate_user_agent(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:user_agent)
    |> validate_length(:user_agent, min: 1, max: 1024)
  end

  defp is_public_ip({_, _, _, _} = ip_address) do
    case ip_address do
      {10, _, _, _} -> false
      {192, 168, _, _} -> false
      {172, second, _, _} when second >= 16 and second <= 31 -> false
      {127, 0, 0, _} -> false
      {_, _, _, _} -> true
      :einval -> false
    end
  end

  defp is_public_ip(_ip_address), do: true
end
