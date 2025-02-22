defmodule Security.Policy do
  @moduledoc """
  Security policy for the Passwordless application.
  """

  alias Passwordless.Accounts.User

  @doc """
  Callback to authorize a user's action.
  """
  @callback authorize(user :: map(), action :: atom(), resource :: any()) :: boolean()

  defmacro __using__(_) do
    quote do
      @behaviour Security.Policy

      alias Passwordless.Accounts.User

      def is?(%User{role: role}, role) when is_atom(role), do: true
      def is?(%User{}, _action), do: false
    end
  end
end
