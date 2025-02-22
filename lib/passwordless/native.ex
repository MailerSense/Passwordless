defmodule Passwordless.Native do
  @moduledoc """
  Native bindings.
  """
  use Rustler,
    crate: "passwordless_native",
    otp_app: :passwordless,
    skip_compilation?: Mix.env() in [:prod, :test]

  alias Passwordless.Scheduler.BalancedConfig
  alias Passwordless.Scheduler.GreedyConfig
  alias Passwordless.Scheduler.Task

  @doc """
  Takes a list of tasks and returns a greedy schedule.
  """
  @spec greedy_schedule(GreedyConfig.t()) :: list(Task.t()) | atom()
  def greedy_schedule(_config), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a list of tasks and returns a balanced schedule.
  """
  @spec balanced_schedule(BalancedConfig.t()) :: list(Task.t()) | atom()
  def balanced_schedule(_config), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes rgba data as a binary in u8 rgba format flattened with 4 values per pixel.
  e.g. <<r1 g1 b1 a1 r2 g2 b2 a2 ...>>
  Returns a list of integer values that make up a thumbhash of the image
  Images must be pre-scaled to fit within a 100px x 100px bounding box.
  """
  @spec rgba_to_thumb_hash(non_neg_integer(), non_neg_integer(), binary()) ::
          list(byte()) | no_return()
  def rgba_to_thumb_hash(_width, _height, _rgba), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a hash as a binary and returns the width, height, and image data.
  """
  @spec thumb_hash_to_rgba(list(byte())) ::
          {:ok, {non_neg_integer(), non_neg_integer(), binary()}} | {:error, any()} | no_return()
  def thumb_hash_to_rgba(_b64_hash), do: :erlang.nif_error(:nif_not_loaded)
end
