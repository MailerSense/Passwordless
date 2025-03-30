defmodule Passwordless.Email.Queue.Source do
  @moduledoc false

  use TypedStruct

  typedstruct do
    field :id, binary(), enforce: true
    field :sqs_queue_url, binary(), enforce: true
  end
end
