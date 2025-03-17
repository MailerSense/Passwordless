defmodule Passwordless.Domain do
  @moduledoc false

  use Passwordless.Schema

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.DomainRecord

  @kinds ~w(root_domain sub_domain)a
  @aws_states ~w(
    aws_pending
    aws_success
    aws_failed
    aws_temporary_failure
    aws_not_started
  )a
  @dns_states ~w(
    all_records_verified
    some_records_missing
  )a
  @states @aws_states ++ @dns_states

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "domains" do
    field :name, :string
    field :kind, Ecto.Enum, values: @kinds, default: :sub_domain
    field :state, Ecto.Enum, values: @states, default: :aws_not_started
    field :verified, :boolean, default: false

    has_many :records, DomainRecord

    belongs_to :app, App, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  def kinds, do: @kinds
  def states, do: @states
  def email_suffix(%__MODULE__{name: name}), do: "@#{name}"

  @doc """
  Map the AWS domain verification states to our internal reprentation.
  """
  def aws_verification_states,
    do: %{
      "Pending" => :aws_pending,
      "Success" => :aws_success,
      "Failed" => :aws_failed,
      "TemporaryFailure" => :aws_temporary_failure,
      "NotStarted" => :aws_not_started
    }

  @doc """
  Map the AWS domain state states to our internal reprentation.
  """
  def aws_states,
    do: %{
      "Pending" => :aws_pending,
      "Success" => :aws_success,
      "Failed" => :aws_failed,
      "TemporaryFailure" => :aws_temporary_failure,
      "NotStarted" => :aws_not_started
    }

  @doc """
  Check if the identity is pending AWS identity state via CNAME.
  """
  def pending_aws_state?(%__MODULE__{state: state}) when state in @aws_states, do: true
  def pending_aws_state?(%__MODULE__{}), do: false

  @doc """
  Check if the identity has successfully been verified via AWS.
  """
  def verified_by_aws?(%__MODULE__{state: :aws_success}), do: true
  def verified_by_aws?(%__MODULE__{}), do: false

  def get_by_state(query \\ __MODULE__, state) do
    from q in query, where: q.state == ^state
  end

  def get_not_verified(query \\ __MODULE__) do
    from q in query, where: not q.verified
  end

  @fields ~w(
    name
    kind
    state
    verified
    app_id
  )a
  @required_fields @fields

  @doc """
  A domain changeset.
  """
  def changeset(%__MODULE__{} = identity, attrs \\ %{}) do
    identity
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_name()
    |> validate_state()
    |> unique_constraint(:name)
    |> unsafe_validate_unique(:name, Passwordless.Repo,
      query: from(d in __MODULE__, where: d.verified and is_nil(d.deleted_at))
    )
    |> assoc_constraint(:app)
  end

  @doc """
  A domain changeset for state changes.
  """
  def state_changeset(%__MODULE__{} = identity, attrs \\ %{}) do
    identity
    |> cast(attrs, [:state])
    |> validate_required([:state])
    |> validate_state()
  end

  # Private

  defp validate_name(changeset) do
    case get_field(changeset, :kind) do
      :sub_domain -> ChangesetExt.validate_subdomain(changeset, :name)
      :root_domain -> ChangesetExt.validate_domain(changeset, :name)
      _ -> add_error(changeset, :kind, "is invalid")
    end
  end

  defp validate_state(changeset) do
    ChangesetExt.validate_state(
      changeset,
      [
        aws_not_started: [:aws_pending, :aws_success],
        aws_pending: [:aws_success, :aws_failed, :aws_temporary_failure],
        aws_temporary_failure: [:aws_pending, :aws_success, :aws_failed, :aws_temporary_failure],
        aws_success: [:all_records_verified, :some_records_missing],
        all_records_verified: [:some_records_missing],
        some_records_missing: [:all_records_verified]
      ],
      :state
    )
  end
end
