defmodule PasswordlessWeb.ErrorReasonJSON do
  @doc """
  Renders custom errors.
  """

  def error(%{reason: reason}) when is_binary(reason) or is_atom(reason) do
    %{error: Phoenix.Naming.humanize(reason)}
  end

  def error(%{reason: reason}) do
    %{error: Phoenix.Naming.humanize(inspect(reason))}
  end
end
