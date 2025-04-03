defmodule AWS.Tools do
  @moduledoc """
  Provides AWS tools & utilities.
  """

  alias AWS.Policy

  @aws Application.compile_env!(:passwordless, :aws)

  @regions @aws |> Keyword.fetch!(:regions) |> Map.keys()
  @default_region Keyword.fetch!(@aws, :region)
  @default_account Keyword.fetch!(@aws, :account)
  @arn_regex ~r/^arn:aws:[A-Za-z0-9_\.-]+:(#{Enum.join(@regions, "|")})?:(\d{12})?:[A-Za-z0-9_\/\.\-\*]+$/

  @doc """
  Parses an AWS IAM JSON policy.
  """
  def sigil_a(policy, []), do: Policy.parse!(policy)

  @doc """
  Provides a canonical regex format for ARNs.
  """
  def arn_format, do: @arn_regex

  @doc """
  Validates an ARN.
  """
  def valid_arn?(arn) when is_binary(arn) do
    Regex.match?(@arn_regex, arn)
  end

  def valid_arn?(_), do: false

  @doc """
  Provides the default AWS region.
  """
  def default_region, do: @default_region

  @doc """
  Provides the default AWS account.
  """
  def default_account, do: @default_account
end
