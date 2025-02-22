defmodule PasswordlessWeb.PageController do
  use PasswordlessWeb, :controller

  action_fallback PasswordlessWeb.FallbackController

  def landing_page(conn, _params) do
    render(conn, :landing_page,
      page_title: gettext("Passwordless: Test Automation, 10x Faster"),
      page_description:
        gettext(
          "More than uptime checks - catch website bugs with Playwright and never miss regressions in production again. No complex setup required. Flexible pricing."
        )
    )
  end

  def product(conn, _params) do
    render(conn, :product,
      page_title: gettext("Product"),
      page_description: gettext("Detect and Resolve Issues 10x Faster With Monitoring-as-Code")
    )
  end

  def pricing(conn, _params) do
    render(conn, :pricing,
      page_title: gettext("Pricing"),
      page_description: gettext("Passwordless Pricing Plans: Flexible Synthetic Monitoring Solution")
    )
  end

  def contact(conn, _params) do
    render(conn, :contact,
      page_title: gettext("Contact"),
      page_description: gettext("Got A Question? We'll Be Happy To Help You"),
      message: build_message_changeset()
    )
  end

  def book(conn, _params) do
    render(conn, :book,
      page_title: gettext("Demo Session"),
      page_description: gettext("Let's Have A Call And See How We Can Help You")
    )
  end

  def docs(conn, _params) do
    render(conn, :docs,
      page_title: gettext("Documentation"),
      page_description: gettext("Livecheck Gives You Code-First Synthetic Monitoring For Modern Devops")
    )
  end

  def guides(conn, _params) do
    render(conn, :guides,
      page_title: gettext("Guides"),
      page_description: gettext("Dive Into Advanced Guides On Monitoring, Testing, And Livecheck Use Cases")
    )
  end

  def terms(conn, _params) do
    render(conn, :terms,
      page_title: gettext("Terms of Service"),
      page_description: gettext("Passwordless Terms of Service")
    )
  end

  def privacy(conn, _params) do
    render(conn, :privacy,
      page_title: gettext("Privacy Policy"),
      page_description: gettext("Passwordless Privacy Policy")
    )
  end

  def development(conn, _params) do
    render(conn, :development,
      page_title: gettext("We're In Development"),
      page_description: gettext("Livecheck Is A Few Months Away From General Availability")
    )
  end

  # Private

  defp build_message_changeset(params \\ %{}) do
    types = %{
      name: :string,
      email: :string,
      message: :string
    }

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:name, :email, :message])
    |> Database.ChangesetExt.validate_email()
  end
end
