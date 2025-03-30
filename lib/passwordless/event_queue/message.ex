defmodule Passwordless.EventQueue.Message do
  @moduledoc """
  A message received from Amazon SQS.
  """

  use TypedStruct

  alias Passwordless.EventQueue.Source

  typedstruct do
    field :id, binary(), enforce: true
    field :data, map()
    field :source, Source.t(), enforce: true
    field :acknowledger, (-> :ok | {:error, any()})
  end

  def ack(%__MODULE__{acknowledger: acknowledger}) when is_function(acknowledger, 0) do
    acknowledger.()
  end

  def ack(%__MODULE__{}), do: :ok
end
