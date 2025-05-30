defmodule PasswordlessApi.ActionTemplateJSON do
  @moduledoc """
  JSON views for API key controller.
  """

  alias Passwordless.ActionTemplate

  def show(%{action_template: %ActionTemplate{} = action_template}) do
    %{action_template: action_template}
  end
end
