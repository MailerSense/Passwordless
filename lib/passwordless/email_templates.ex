defmodule Passwordless.EmailTemplates do
  @moduledoc """
  Email templates for Passwordless.
  """

  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.App

  def get_seed(%App{} = app, authenticator, language, style) do
    seeds = seeds(app)
    fallback_language = get_in(seeds, [authenticator, :en])
    fallback_style = get_in(fallback_language.styles, [fallback_language.style])
    language_map = get_in(seeds, [authenticator, Access.key(language, fallback_language)])
    style_map = get_in(language_map, [:styles, Access.key(style, fallback_style)])
    language_map |> Map.merge(style_map) |> Map.drop([:styles])
  end

  def seeds(%App{} = app),
    do: %{
      magic_link: %{
        en: %{
          name: gettext("Magic link template"),
          style: :magic_link_clean,
          subject: gettext("Sign in to %{name}", name: app.settings.display_name),
          preheader: gettext("Magic Link to {{ action.name}}"),
          styles: %{
            magic_link_clean: %{
              mjml_body:
                Passwordless.Formatter.format!(
                  ~S"""
                  <mjml>
                    <mj-head>
                      <mj-title>{{ subject }}</mj-title>
                      <mj-preview>{{ preheader }}</mj-preview>
                      <mj-attributes>
                        <mj-all font-size="14px" line-height="26px" font-family="inter, sans-serif" line-height="36px" />
                        <mj-button
                          color="#FFFFFF"
                          background-color="{{ app.primary_button_color }}"
                          font-family="inter, sans-serif"
                        ></mj-button>
                      </mj-attributes>
                    </mj-head>
                    <mj-body background-color="#ebf2fa">
                      <mj-section>
                        <mj-column>
                          <mj-image src="https://res.cloudinary.com/kissassets/image/upload/v1556188010/logo.png" width="140px" alt="logo" />
                        </mj-column>
                      </mj-section>
                      <mj-section>
                        <mj-column background-color="#fff" css-class="body-section" border-top="4px solid #2294ed" padding="15px">
                          <mj-text padding="16px" align="left">
                            <h4>Your {{ app.display_name }}'s Magic Link</h4>
                            Please click the magic link below to {{ action.name }} with {{ app.display_name }}.
                          </mj-text>
                          <mj-button href="{{ magic_link_url }}" padding-bottom="24px">
                            {{ action.name }} with {{ app.display_name }}
                          </mj-button>
                          <mj-text container-background-color="#f3f9ff">
                            Or copy and paste this URL into your browser:
                            <a href="{{ magic_link_url }}" style="line-height: 1.6">{{ magic_link_url }}</a>
                          </mj-text>
                          <mj-divider border-width="1px" border-color="#8ba6c0" border-style="dashed" />
                          <mj-text>
                            This link is valid for 3 minutes.
                          </mj-text>
                        </mj-column>
                      </mj-section>
                      <mj-section>
                        <mj-column>
                          <mj-text align="center" line-height="1.6">
                            This is your {{ app.display_name }}'s magic link.<br />if you didn't attempt to {{ action.name }}, you can safely ignore this email.
                          </mj-text>
                          <mj-text align="center" line-height="1.6">
                            <a href="{{ unsubscribe_url }}">Unsubscribe</a>
                          </mj-text>
                        </mj-column>
                      </mj-section>
                    </mj-body>
                  </mjml>
                  """,
                  :html
                )
            }
          }
        }
      },
      email_otp: %{
        en: %{
          name: gettext("Email OTP template"),
          style: :email_otp_clean,
          subject: gettext("Sign in to %{name}", name: app.settings.display_name),
          preheader: gettext("Enter {{ otp_code }} to {{ action.name}}"),
          styles: %{
            email_otp_clean: %{
              mjml_body:
                Passwordless.Formatter.format!(
                  ~S"""
                  <mjml>
                    <mj-head>
                      <mj-title>{{ subject }}</mj-title>
                      <mj-preview>{{ preheader }}</mj-preview>
                      <mj-attributes>
                        <mj-all font-size="14px" line-height="26px" font-family="inter, sans-serif" line-height="36px" />
                      </mj-attributes>
                    </mj-head>
                    <mj-body background-color="#ebf2fa">
                      <mj-section>
                        <mj-column>
                          <mj-image src="https://res.cloudinary.com/kissassets/image/upload/v1556188010/logo.png" width="140px" alt="logo" />
                        </mj-column>
                      </mj-section>
                      <mj-section>
                        <mj-column background-color="#fff" width="320px" css-class="body-section" border-top="4px solid #2e90fa" padding="15px">
                          <mj-image src="https://res.cloudinary.com/kissassets/image/upload/v1556264522/password-lock.png" align="center" width="150px" alt="" />
                          <mj-text font-size="24px" align="center">
                            Code to {{ action.name }}
                          </mj-text>
                          <mj-text font-family="monospace" font-size="32px" align="center" container-background-color="#f3f9ff" font-weight="600" letter-spacing="8px">
                            {{ otp_code }}
                          </mj-text>
                          <mj-divider border-width="1px" border-color="#8ba6c0" border-style="dashed" />
                          <mj-text align="center">
                            Valid for next 3 minutes
                          </mj-text>
                        </mj-column>
                      </mj-section>
                      <mj-section>
                        <mj-column>
                          <mj-text align="center" line-height="1.6">
                            This is your {{ app.display_name }}'s one time password.<br />if you didn't attempt to {{ action.name }}, you can safely ignore this email.
                          </mj-text>
                          <mj-text align="center" line-height="1.6">
                            <a href="{{ unsubscribe_url }}">Unsubscribe</a>
                          </mj-text>
                        </mj-column>
                      </mj-section>
                    </mj-body>
                  </mjml>
                  """,
                  :html
                )
            }
          }
        }
      }
    }
end
