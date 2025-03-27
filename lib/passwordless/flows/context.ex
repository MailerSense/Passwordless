defmodule Passwordless.Flows.Context do
  @moduledoc false

  use TypedStruct

  typedstruct do
    field :app, map(), enforce: true
    field :actor, map(), enforce: true
    field :action, map(), enforce: true
  end
end
