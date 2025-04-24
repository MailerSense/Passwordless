defmodule Passwordless.EmailTemplates do
  @moduledoc """
  Email templates for Passwordless.
  """

  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.App

  def get_seed(%App{} = app, kind, language \\ :en) do
    seeds = seeds(app)
    fallback = get_in(seeds, [kind, :en])

    get_in(seeds, [kind, Access.key(language, fallback)])
  end

  def seeds(%App{} = app),
    do: %{
      magic_link_sign_in: %{
        en: %{
          name: gettext("Magic link template"),
          style: :magic_link_clean,
          subject: gettext("Sign in to %{name}", name: app.settings.display_name),
          preheader: gettext("Click the link below to sign in."),
          mjml_body:
            Passwordless.Formatter.format!(
              ~S"""
              <mjml>
                <mj-head>
                  <mj-title>{{ subject }}</mj-title>
                  <mj-preview>{{ preheader }}</mj-preview>
                  <mj-attributes>
                    <mj-text
                      font-size="16px"
                      line-height="1.6"
                      color="#111827"
                      font-family="inter, sans-serif"
                    ></mj-text>
                    <mj-button
                      font-size="16px"
                      line-height="1.6"
                      color="#111827"
                      background-color="#1570ef"
                      font-family="inter, sans-serif"
                    ></mj-button>
                  </mj-attributes>
                  <mj-style inline="inline">
                    a { color: inherit; text-decoration: underline; }
                  </mj-style>
                </mj-head>
                <mj-body background-color="#f3f4f6">
                  <mj-section>
                    <mj-column>
                      <mj-image
                        width="100px"
                        height="100px"
                        src="{{ app.logo }}"
                      ></mj-image>
                    </mj-column>
                  </mj-section>
                  <mj-section background-color="#ffffff">
                    <mj-column>
                      <mj-text>
                        Hey {{user.name | default: "there" }}, here is your login for <strong>{{ app.display_name }}</strong>:
                      </mj-text>
                      <mj-button color="#ffffff" font-weight="600" border-radius="8px" href="{{ magic_link_url }}">
                        Sign in to {{ app.display_name }}
                      </mj-button>
                      <mj-text>Or, copy and paste this link into your browser:</mj-text>
                      <mj-text color="#1570ef"><a href="{{ magic_link_url }}" target="_blank">{{ magic_link_url }}</a></mj-text>
                      <mj-text color="#999999"
                      >This email was sent by <a href="https://appfarm.io" target="_blank" style="color: #999999;">Passwordless</a> on behalf of {{ app.display_name }}. If
                        you did not request this email, please reply and let us know.</mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-section
                    background-url="https://www.keila.io/newsletter-assets/ai-elephant.jpg"
                    padding="20px 20px"
                  >
                    <mj-column></mj-column>
                    <mj-column background-color="#dcfce7">
                      <mj-text>
                        MJML is an easy way to create complex email layouts with multiple columns that are fully responsive and work on a wide range of devices.
                      </mj-text>
                      <mj-text>
                        Lorem Ipsum Dolor Sit Amet Consecuteor Est Lirum Larum.
                      </mj-text>
                      <mj-button
                        background-color="#111827"
                        color="white"
                        href="https://www.keila.io"
                      >
                        Click me!
                      </mj-button>
                    </mj-column>
                  </mj-section>
                  <mj-section background-color="#ffffff" padding-bottom="0">
                    <mj-column>
                      <mj-text font-weight="bold"> Use Multiple Columns! </mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-section background-color="#ffffff" padding-top="0">
                    <mj-column>
                      <mj-text>Build responsive email templates with MJML.</mj-text>
                    </mj-column>
                    <mj-column>
                      <mj-text>Use the <code>&lt;mj-raw&gt;</code> tag to include
                        <a href="https://shopify.github.io/liquid/" target="_blank">Liquid template</a>
                        tags.</mj-text>
                    </mj-column>
                    <mj-column>
                      <mj-text>If you prefer simpler emails, you can also write newsletters in Markdown!</mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-section>
                    <mj-column>
                      <mj-text align="center">The following sections are dynamically generated with Liquid:</mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-raw>{% assign colors = "#41b8da,#8bb746,#0b3622" | split: "," %}</mj-raw>
                  <mj-raw>{% for color in colors %}</mj-raw>
                  <mj-section background-color="{{ color }}" padding="20px">
                    <mj-column padding-top="20px">
                      <mj-text font-size="31px" color="#ffffff">{{ color }}</mj-text>
                    </mj-column>
                    <mj-column background-color="#ffffff">
                      <mj-text font-size="18px" font-weight="bold">Section #{{forloop.index}}</mj-text>
                      <mj-text> This is a dynamically generated section. </mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-raw>{% endfor %}</mj-raw>
                  <mj-section>
                    <mj-column>
                      <mj-text font-size="12.5px" align="center">
                        Powered by Keila - Open Source Newsletters
                        <br />
                        <a style="color: #292524" href="{{unsubscribe_link}}">Unsubscribe</a>
                      </mj-text>
                    </mj-column>
                  </mj-section>
                </mj-body>
              </mjml>
              """,
              :html
            )
        }
      },
      email_otp_sign_in: %{
        en: %{
          name: gettext("Email OTP template"),
          style: :email_otp_clean,
          subject: gettext("Sign in to %{name}", name: app.settings.display_name),
          preheader: gettext("Your OTP is {{ otp_code }}."),
          mjml_body:
            Passwordless.Formatter.format!(
              ~S"""
              <mjml>
                <mj-head>
                  <mj-title>{{ subject }}</mj-title>
                  <mj-preview>{{ preheader }}</mj-preview>
                  <mj-attributes>
                    <mj-text
                      font-size="16px"
                      line-height="1.6"
                      color="#111827"
                      font-family="inter, sans-serif"
                    ></mj-text>
                    <mj-button
                      font-size="16px"
                      line-height="1.6"
                      color="#111827"
                      background-color="#1570ef"
                      font-family="inter, sans-serif"
                    ></mj-button>
                  </mj-attributes>
                  <mj-style inline="inline">
                    a { color: inherit; text-decoration: underline; }
                  </mj-style>
                </mj-head>
                <mj-body background-color="#f3f4f6">
                  <mj-section>
                    <mj-column>
                      <mj-image
                        width="100px"
                        height="100px"
                        src="{{ app.logo }}"
                      ></mj-image>
                    </mj-column>
                  </mj-section>
                  <mj-section background-color="#ffffff">
                    <mj-column>
                      <mj-text>
                        Hey {{user.name | default: "there" }}, here is your OTP for <strong>{{ app.display_name }}</strong>:
                      </mj-text>
                      <mj-text align="center" letter-spacing="8px" font-weight="500" font-size="56px" >{{ otp_code }}</mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-section
                    background-url="https://www.keila.io/newsletter-assets/ai-elephant.jpg"
                    padding="20px 20px"
                  >
                    <mj-column></mj-column>
                    <mj-column background-color="#dcfce7">
                      <mj-text>
                        MJML is an easy way to create complex email layouts with multiple columns that are fully responsive and work on a wide range of devices.
                      </mj-text>
                      <mj-text>
                        Lorem Ipsum Dolor Sit Amet Consecuteor Est Lirum Larum.
                      </mj-text>
                      <mj-button
                        background-color="#111827"
                        color="white"
                        href="https://www.keila.io"
                      >
                        Click me!
                      </mj-button>
                    </mj-column>
                  </mj-section>
                  <mj-section background-color="#ffffff" padding-bottom="0">
                    <mj-column>
                      <mj-text font-weight="bold"> Use Multiple Columns! </mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-section background-color="#ffffff" padding-top="0">
                    <mj-column>
                      <mj-text>Build responsive email templates with MJML.</mj-text>
                    </mj-column>
                    <mj-column>
                      <mj-text>Use the <code>&lt;mj-raw&gt;</code> tag to include
                        <a href="https://shopify.github.io/liquid/" target="_blank">Liquid template</a>
                        tags.</mj-text>
                    </mj-column>
                    <mj-column>
                      <mj-text>If you prefer simpler emails, you can also write newsletters in Markdown!</mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-section>
                    <mj-column>
                      <mj-text align="center">The following sections are dynamically generated with Liquid:</mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-raw>{% assign colors = "#41b8da,#8bb746,#0b3622" | split: "," %}</mj-raw>
                  <mj-raw>{% for color in colors %}</mj-raw>
                  <mj-section background-color="{{ color }}" padding="20px">
                    <mj-column padding-top="20px">
                      <mj-text font-size="31px" color="#ffffff">{{ color }}</mj-text>
                    </mj-column>
                    <mj-column background-color="#ffffff">
                      <mj-text font-size="18px" font-weight="bold">Section #{{forloop.index}}</mj-text>
                      <mj-text> This is a dynamically generated section. </mj-text>
                    </mj-column>
                  </mj-section>
                  <mj-raw>{% endfor %}</mj-raw>
                  <mj-section>
                    <mj-column>
                      <mj-text font-size="12.5px" align="center">
                        Powered by Keila - Open Source Newsletters
                        <br />
                        <a style="color: #292524" href="{{unsubscribe_link}}">Unsubscribe</a>
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
end
