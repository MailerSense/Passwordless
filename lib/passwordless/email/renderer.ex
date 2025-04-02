defmodule Passwordless.Email.Renderer do
  @moduledoc false

  import Swoosh.Email

  alias Passwordless.EmailTemplateVersion
  alias Passwordless.Templating.Liquid
  alias Passwordless.Templating.MJML

  @variable_providers [
    :app,
    :actor,
    :action
  ]

  def render(%EmailTemplateVersion{mjml_body: mjml_body} = email_template_version, attrs \\ %{}, opts \\ []) do
    variables = Map.get(attrs, :variables, %{})
    provider_variables = Map.take(attrs, @variable_providers)

    variables = Map.merge(variables, provider_variables)

    with {:ok, body} <- Liquid.render(mjml_body, variables, opts),
         {:ok, body} <- MJML.convert(body) do
      {:ok, nil}
    end
  end

  defp render_body(
         %{
           contact: %Contact{} = contact,
           template: %Template{} = template,
           template_variant: %TemplateVariant{} = template_variant
         },
         assigns
       )
       when is_map(assigns) do
    styles = Template.get_styles(template)

    case get_body_blocks(template_variant.json_content, assigns) do
      {:ok, body_blocks} ->
        embedded_css =
          styles
          |> Enum.filter(fn {selector, _} ->
            selector in Layout.embedded_styles(template.layout)
          end)
          |> CSS.encode(styles)

        assigns =
          %{
            "body_blocks" => body_blocks,
            "embedded_css" => embedded_css,
            "html_body_class" => "keila--block-campaign"
          }
          |> Map.put("contact", Util.deep_struct_to_map(contact))
          |> Map.merge(Map.take(assigns, ["variables"]))

        case Liquid.render(Layout.body(template.layout), assigns, file_system: Layout.file_system(template.layout)) do
          {:ok, html_body} ->
            html_body =
              html_body
              |> Html.parse_document!()
              |> Html.apply_inline_styles(styles, ignore_inherit: true)
              |> Html.to_document()

            {:ok, html_body}

          error ->
            error
        end

      error ->
        error
    end
  end
end
