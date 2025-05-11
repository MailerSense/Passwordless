defmodule Passwordless.Email.Renderer do
  @moduledoc """
  Renders email templates using MJML and Liquid.
  """

  alias Passwordless.Action
  alias Passwordless.ActionTemplate
  alias Passwordless.Email
  alias Passwordless.EmailTemplateLocale
  alias Passwordless.Identifier
  alias Passwordless.OTP
  alias Passwordless.Phone
  alias Passwordless.Templating.Liquid
  alias Passwordless.Templating.MJML
  alias Passwordless.Templating.Scrubber
  alias Passwordless.Templating.VariableProvider
  alias Passwordless.User

  @example_providers [
    user: %User{
      language: :en,
      data: %{
        "key1" => "value1",
        "key2" => "value2"
      },
      email: %Email{
        address: "john.doe@company.com"
      },
      phone: %Phone{
        canonical: "+491234567890"
      },
      identifier: %Identifier{
        value: "473242b7-dc21-45fb-8751-ae0bc86c05b3"
      }
    },
    action: %Action{
      template: %ActionTemplate{
        name: "Sign In",
        alias: "signIn"
      }
    }
  ]

  @example_variables %{
    "otp_code" => "123456",
    "magic_link_url" =>
      "https://eu.passwordless.tools/auth/sign-in/passwordless/complete/SFMyNTY.g2gDbQAAACAjqIsr8_fd6TsBwSqcV0GuDCesLQrEV4ohzfT9qOKJUW4GAMVHZR-WAWIAAVGA.SCmssWIvn_DD1DChLdU_LgStbWcDIqLOf1nwwMdwRzs",
    "unsubscribe_url" => "https://eu.passwordless.tools/auth/unsubscribe/1234567890"
  }

  @variable_providers [
    :otp,
    :app,
    :user,
    :action
  ]

  def demo_opts,
    do:
      @example_providers ++
        [otp: %OTP{code: OTP.generate_code(), expires_at: DateTime.add(DateTime.utc_now(), 3, :minute)}]

  def demo_variables, do: @example_variables

  def render(%EmailTemplateLocale{mjml_body: mjml_body} = email_template_locale, variables \\ %{}, opts \\ []) do
    variables = prepare_variables(email_template_locale, variables, opts)

    with {:ok, subject} <- Map.fetch(variables, "subject"),
         {:ok, mjml_body} <- Liquid.render(mjml_body, variables),
         {:ok, html_body} <- MJML.convert(mjml_body) do
      html_body = Scrubber.clean_html(html_body)

      {:ok,
       %{
         subject: subject,
         html_content: html_body,
         text_content: Premailex.to_text(html_body),
         email_template_locale_id: email_template_locale.id
       }}
    end
  end

  def prepare_variables(%EmailTemplateLocale{subject: subject, preheader: preheader}, variables \\ %{}, opts \\ []) do
    provider_variables =
      opts
      |> Keyword.take(@variable_providers)
      |> Enum.reject(&Util.blank?/1)
      |> Enum.reduce(%{}, fn {_key, mod}, acc ->
        Map.put(acc, VariableProvider.name(mod), VariableProvider.variables(mod))
      end)

    variables =
      variables
      |> Map.merge(provider_variables)
      |> Util.stringify_keys()

    variables =
      case Liquid.render(subject, variables) do
        {:ok, subject} -> Map.put(variables, "subject", subject)
        _ -> variables
      end

    variables =
      case Liquid.render(preheader, variables) do
        {:ok, preheader} -> Map.put(variables, "preheader", preheader)
        _ -> variables
      end

    variables
  end
end
