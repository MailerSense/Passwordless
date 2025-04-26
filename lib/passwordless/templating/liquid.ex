defmodule Passwordless.Templating.Liquid do
  @moduledoc """
  Module to safely render Liquid templates from strings or pre-pared by `Solid`.
  """

  @doc """
  Safely renders a liquid template to a string.

  Solid can sometimes raise exceptions when rendering invalid templates, this
  module catches these exceptions and transforms them into an error tuple.
  """
  def render(input, assigns, opts \\ []) when is_binary(input) and is_map(assigns) do
    case Solid.parse(input) do
      {:ok, template} -> render_template(template, assigns, opts)
      {:error, %Solid.TemplateError{} = error} -> {:error, template_error_to_string(error)}
    end
  end

  # Private

  defp render_template(%Solid.Template{} = input, assigns, opts) when is_map(assigns) do
    case Solid.render(input, assigns, opts) do
      {:ok, rendered} -> {:ok, to_string(rendered)}
      {:error, errors, _rest} -> {:error, Enum.map_join(errors, ", ", &decode_rendering_error/1)}
    end
  end

  defp decode_rendering_error(%Solid.UndefinedVariableError{} = error), do: Solid.UndefinedVariableError.exception(error)
  defp decode_rendering_error(%Solid.UndefinedFilterError{} = error), do: Solid.UndefinedFilterError.exception(error)
  defp decode_rendering_error(error), do: inspect(error)

  defp template_error_to_string(%{line: {line, _}, reason: reason}) do
    "Parsing error in line #{line}: #{reason}"
  end
end
