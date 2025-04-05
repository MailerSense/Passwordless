defmodule Passwordless.Templating.Liquid do
  @moduledoc """
  Module to safely render Liquid templates from strings or pre-pared by `Solid`.
  """

  @doc """
  Safely renders a liquid template to a string.

  Solid can sometimes raise exceptions when rendering invalid templates, this
  module catches these exceptions and transforms them into an error tuple.
  """

  def render(input, assigns, opts \\ [])

  def render(input, assigns, opts) when is_binary(input) and is_map(assigns) do
    case Solid.parse(input) do
      {:ok, template} -> render(template, assigns, opts)
      {:error, %Solid.TemplateError{} = error} -> {:error, template_error_to_string(error)}
    end
  rescue
    e -> {:error, :invalid_liquid}
  end

  def render(%Solid.Template{} = input, assigns, opts) when is_map(assigns) do
    {:ok, input |> Solid.render!(assigns, opts) |> to_string()}
  rescue
    e -> {:error, :invalid_liquid}
  end

  # Private

  defp template_error_to_string(%{line: {line, _}, reason: reason}) do
    "Parsing error in line #{line}: #{reason}"
  end
end
