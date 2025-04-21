defmodule PasswordlessApi.ActorJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.Actor

  def get(%{actor: %Actor{} = actor}) do
    %{actor: actor}
  end
end
