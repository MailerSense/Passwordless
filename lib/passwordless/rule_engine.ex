defprotocol ExpressionHasher do
  @moduledoc false

  @spec hash(t) :: binary()
  def hash(expr)
end

defmodule Passwordless.RuleEngine do
  @moduledoc """
  The core logic of the authentication rule engine.
  """

  alias Passwordless.Rule
  alias Util.Bin

  defmodule BooleanCondition do
    @moduledoc false
    use TypedStruct

    typedstruct do
      field :value, boolean(), enforce: true
    end
  end

  defmodule AndCondition do
    @moduledoc false
    use TypedStruct

    typedstruct do
      field :predicates, list(map()), enforce: true
    end
  end

  defmodule OrCondition do
    @moduledoc false
    use TypedStruct

    typedstruct do
      field :predicates, list(map()), enforce: true
    end
  end

  defmodule IPAddressCondition do
    @moduledoc false
    use TypedStruct
    use Drops.Contract

    typedstruct do
      field :country_code, binary()
      field :is_anonymous, boolean()
    end

    schema(atomize: true) do
      %{
        optional(:country_code) => string(:filled?),
        optional(:is_anonymous) => boolean()
      }
    end
  end

  defmodule ActionCondition do
    @moduledoc false
    use TypedStruct
    use Drops.Contract

    typedstruct do
      field :name, binary(), enforce: true
      field :state, binary()
    end

    schema(atomize: true) do
      %{
        required(:name) => string(:filled?),
        optional(:state) => string(:filled?)
      }
    end
  end

  defmodule EmailOTPEffect do
    @moduledoc false
    use TypedStruct
    use Drops.Contract

    typedstruct do
      field :challenge, binary(), enforce: true
      field :with, map()
    end

    schema(atomize: true) do
      %{
        required(:challenge) => string(:filled?),
        optional(:with) => %{
          optional(:email) => string(:filled?)
        }
      }
    end
  end

  def parse(%{if: condition, then: effects}) when not is_nil(condition) and is_list(effects) do
    condition = parse_condition(condition)
    effects = Enum.map(effects, &parse_effect/1)

    hash =
      "cn:" <>
        ExpressionHasher.hash(condition) <>
        ":ef:" <>
        Enum.map_join(effects, Bin.sep(), &ExpressionHasher.hash/1)

    {:ok, %Rule{condition: Util.convert(condition), effects: Util.convert(effects), hash: hash}}
  end

  # Private

  defp parse_condition(input) when is_boolean(input) do
    %BooleanCondition{value: input}
  end

  defp parse_condition(%{"and" => predicates}) when is_list(predicates) do
    %AndCondition{predicates: Enum.map(predicates, &parse_condition/1)}
  end

  defp parse_condition(%{"or" => predicates}) when is_list(predicates) do
    %OrCondition{predicates: Enum.map(predicates, &parse_condition/1)}
  end

  defp parse_condition(%{"ip_address" => ip_address}) when is_map(ip_address) do
    {:ok, schema} = IPAddressCondition.conform(ip_address)
    struct!(IPAddressCondition, schema)
  end

  defp parse_condition(%{"action" => action}) when is_map(action) do
    {:ok, schema} = ActionCondition.conform(action)
    struct!(ActionCondition, schema)
  end

  defp parse_effect(%{"challenge" => "email_otp"} = effect) do
    {:ok, schema} = EmailOTPEffect.conform(effect)
    struct!(EmailOTPEffect, schema)
  end
end

defimpl ExpressionHasher, for: Passwordless.RuleEngine.BooleanCondition do
  alias Passwordless.RuleEngine.BooleanCondition
  alias Util.Bin

  def hash(%BooleanCondition{value: value}), do: "bo:" <> Bin.wire(value)
end

defimpl ExpressionHasher, for: Passwordless.RuleEngine.AndCondition do
  alias Passwordless.RuleEngine.AndCondition
  alias Util.Bin

  def hash(%AndCondition{predicates: predicates}), do: "an:" <> Bin.wire_map(predicates, &ExpressionHasher.hash/1)
end

defimpl ExpressionHasher, for: Passwordless.RuleEngine.OrCondition do
  alias Passwordless.RuleEngine.OrCondition
  alias Util.Bin

  def hash(%OrCondition{predicates: predicates}), do: "or:" <> Bin.wire_map(predicates, &ExpressionHasher.hash/1)
end

defimpl ExpressionHasher, for: Passwordless.RuleEngine.IPAddressCondition do
  alias Passwordless.RuleEngine.IPAddressCondition
  alias Util.Bin

  def hash(%IPAddressCondition{country_code: country_code, is_anonymous: is_anonymous}) do
    "ip:" <> Bin.wire([country_code, is_anonymous])
  end
end

defimpl ExpressionHasher, for: Passwordless.RuleEngine.ActionCondition do
  alias Passwordless.RuleEngine.ActionCondition
  alias Util.Bin

  def hash(%ActionCondition{name: name, state: state}) do
    "ac:" <> Bin.wire([name, state])
  end
end
