defmodule Passwordless.Domain do
  @moduledoc """
  A web domain used for sending emails and tracking email opens and clicks.
  """

  use Passwordless.Schema, prefix: "domain"

  import Database.QueryExt
  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.App
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
  @other_states ~w(
    unhealthy
    under_review
  )a
  @states @aws_states ++ @dns_states ++ @other_states

  @purposes ~w(email tracking)a
  @tags ~w(system default)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :name,
      :kind,
      :state,
      :verified,
      :records,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "domains" do
    field :name, :string
    field :kind, Ecto.Enum, values: @kinds, default: :sub_domain
    field :state, Ecto.Enum, values: @states, default: :aws_not_started
    field :purpose, Ecto.Enum, values: @purposes, default: :email
    field :verified, :boolean, default: false
    field :tags, {:array, Ecto.Enum}, values: @tags, default: []

    has_many :records, DomainRecord, preload_order: [asc: :inserted_at]

    belongs_to :app, App

    timestamps()
    soft_delete_timestamp()
  end

  def kinds, do: @kinds
  def states, do: @states
  def purposes, do: @purposes

  @doc """
  Get the domain name.
  """
  def email_suffix(%__MODULE__{name: name}), do: "@#{name}"

  @doc """
  Check if the domain is a system domain.
  """
  def is_system?(%__MODULE__{tags: tags}) do
    Enum.member?(tags, :system)
  end

  @doc """
  Get the domain by tags.
  """
  def get_by_tags(query \\ __MODULE__, tags) when is_list(tags) do
    tags = Enum.map(tags, &Atom.to_string/1)
    from q in query, where: contains(q.tags, ^tags)
  end

  @doc """
  Produce the AWS ARN for the domain.
  """
  def arn(%__MODULE__{name: name}, region, account) do
    "arn:aws:ses:#{region}:#{account}:identity/#{name}"
  end

  def arn(_, _, _), do: nil

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
    purpose
    verified
    tags
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
    |> validate_tags()
    |> unique_constraint([:app_id, :purpose], error_key: :purpose)
    |> unsafe_validate_unique([:app_id, :purpose], Passwordless.Repo, error_key: :purpose)
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
      aws_not_started: [:aws_pending, :aws_success],
      aws_pending: [:aws_success, :aws_failed, :aws_temporary_failure],
      aws_temporary_failure: [:aws_pending, :aws_success, :aws_failed, :aws_temporary_failure],
      aws_success: [:all_records_verified, :some_records_missing],
      all_records_verified: [:some_records_missing],
      some_records_missing: [:all_records_verified],
      all_records_verified: [:aws_success, :some_records_missing, :unhealthy, :under_review],
      unhealthy: [:aws_success, :some_records_missing, :unhealthy, :under_review],
      under_review: [:aws_success, :some_records_missing, :unhealthy, :under_review]
    )
  end

  defp validate_tags(changeset) do
    ChangesetExt.clean_array(changeset, :tags)
  end
end
