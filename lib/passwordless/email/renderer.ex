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

  def render(
        %EmailTemplateVersion{subject: subject, preheader: preheader, mjml_body: mjml_body} = email_template_version,
        variables \\ %{},
        opts \\ []
      ) do
    provider_variables =
      opts
      |> Keyword.take(@variable_providers)
      |> Enum.reject(&Util.blank?/1)
      |> Enum.reduce(%{}, fn {_key, mod}, acc ->
        Map.put(acc, VariableProvider.name(mod), VariableProvider.variables(mod))
      end)

    variables = Map.merge(variables, provider_variables)

    variables =
      case Liquid.render(subject, variables) do
        {:ok, subject} -> Map.put(variables, :subject, subject)
        _ -> variables
      end

    variables =
      case Liquid.render(preheader, variables) do
        {:ok, preheader} -> Map.put(variables, :preheader, preheader)
        _ -> variables
      end

    variables = Util.stringify_keys(variables)

    with {:ok, subject} <- Map.fetch(variables, "subject"),
         {:ok, mjml_body} <- Liquid.render(mjml_body, variables),
         {:ok, html_body} <- MJML.convert(mjml_body) do
      {:ok,
       %{
         subject: subject,
         html_content: html_body,
         text_content: Premailex.to_text(html_body),
         email_template_version_id: email_template_version.id
       }}
    end
  end
end
