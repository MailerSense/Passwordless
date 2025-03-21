defmodule AWS.Policy do
  @moduledoc """
  Represents an AWS IAM policy.
  """

  use TypedStruct

  alias AWS.Policy.Statement

  typedstruct do
    field :id, binary()
    field :version, binary()
    field :statements, list(Statement.t()), enforce: true
  end

  def parse(policy) do
    parsed = parse!(policy)
    {:ok, parsed}
  rescue
    e in ArgumentError -> {:error, :policy_invalid, e}
  end

  def parse!(policy) when is_binary(policy) do
    parse!(Jason.decode!(policy))
  end

  def parse!(%{"Statement" => statements} = json_policy) when is_list(statements) do
    id = json_policy["Id"]
    version = json_policy["Version"]

    %__MODULE__{
      id: id,
      version: version,
      statements: Enum.map(statements, &Statement.parse!/1)
    }
  end

  def parse!(_), do: raise(ArgumentError, "invalid policy statement")

  def merge!(%__MODULE__{} = policy, %__MODULE__{} = other_policy) do
    %__MODULE__{
      id: policy.id || other_policy.id,
      version: policy.version || other_policy.version,
      statements: policy.statements ++ other_policy.statements
    }
  end

  def validate(policy) when is_binary(policy) or is_map(policy) do
    parse!(policy)
    :ok
  rescue
    e in ArgumentError -> {:error, :policy_invalid, e}
  end
end

defmodule AWS.Policy.Statement do
  @moduledoc """
  Represents an AWS IAM policy statement.
  """

  use TypedStruct

  typedstruct do
    field :sid, binary()
    field :effect, :allow | :deny, enforce: true
    field :principal, map(), enforce: true
    field :not_principal, map(), enforce: true
    field :action, list(), enforce: true
    field :not_action, list(), enforce: true
    field :resource, binary(), enforce: true
    field :not_resource, binary(), enforce: true
    field :condition, map()
  end

  def parse!(%{"Effect" => effect} = statement) when effect in ~w(Allow Deny) do
    sid = statement["Sid"]
    principal = statement["Principal"] && parse_principal!(statement["Principal"])
    not_principal = statement["NotPrincipal"] && parse_principal!(statement["NotPrincipal"])
    action = statement["Action"] && parse_action!(statement["Action"])
    not_action = statement["NotAction"] && parse_action!(statement["NotAction"])
    resource = statement["Resource"] && parse_resource!(statement["Resource"])
    not_resource = statement["NotResource"] && parse_resource!(statement["NotResource"])
    condition = statement["Condition"]

    %__MODULE__{
      sid: sid,
      effect: String.to_atom(String.downcase(effect)),
      principal: principal,
      not_principal: not_principal,
      action: action,
      not_action: not_action,
      resource: resource,
      not_resource: not_resource,
      condition: condition
    }
  end

  def parse!(statement) do
    raise ArgumentError, "invalid statement: #{inspect(statement)}"
  end

  def sid(%__MODULE__{sid: sid}), do: sid

  # Private

  defp parse_principal!("*"), do: :all

  defp parse_principal!(principal_map) when is_map(principal_map) do
    principals =
      Enum.reduce(~w(AWS Federated Service CanonicalUser), [], fn kind, acc ->
        case Map.get(principal_map, kind) do
          "*" -> [{String.to_atom(kind), :all} | acc]
          principal when is_binary(principal) -> [{String.to_atom(kind), [principal]} | acc]
          principals when is_list(principals) -> Enum.map(principals, fn p -> {String.to_atom(kind), [p]} end) ++ acc
          _ -> acc
        end
      end)

    if Enum.empty?(principals) do
      raise ArgumentError, "invalid principal: #{inspect(principal_map)}"
    end

    principals
  end

  defp parse_action!("*"), do: :all
  defp parse_action!(actions) when is_list(actions), do: actions

  defp parse_resource!("*"), do: :all
  defp parse_resource!(resource) when is_binary(resource), do: parse_resource_literal!(resource)
  defp parse_resource!(resources) when is_list(resources), do: Enum.map(resources, &parse_resource_literal!/1)

  defp parse_resource_literal!("arn:" <> _rest = arn) do
    if AWS.Tools.valid_arn?(arn),
      do: arn,
      else: raise(ArgumentError, "invalid ARN: #{inspect(arn)}")
  end

  defp parse_resource_literal!(literal), do: literal
end
