defmodule Passwordless.Email.Renderer do
  @moduledoc """
  Renders email templates using MJML and Liquid.
  """

  alias Passwordless.EmailTemplateVersion
  alias Passwordless.Templating.Liquid
  alias Passwordless.Templating.MJML
  alias Passwordless.Templating.VariableProvider

  @variable_providers [
    :app,
    :actor,
    :action
  ]

  def render(%EmailTemplateVersion{mjml_body: mjml_body} = email_template_version, attrs \\ %{}, opts \\ []) do
    variables = Map.get(attrs, :variables, %{})

    provider_variables =
      attrs
      |> Map.take(@variable_providers)
      |> Enum.reject(&Util.blank?/1)
      |> Enum.reduce(%{}, fn {_key, mod}, acc ->
        Map.merge(acc, VariableProvider.provide(mod))
      end)

    variables = Map.merge(variables, provider_variables)

    with {:ok, body} <- Liquid.render(mjml_body, variables, opts),
         {:ok, body} <- MJML.convert(body) do
      {:ok, nil}
    end
  end
end
