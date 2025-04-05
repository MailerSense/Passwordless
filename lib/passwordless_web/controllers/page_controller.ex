defmodule PasswordlessWeb.PageController do
  use PasswordlessWeb, :controller

  action_fallback PasswordlessWeb.FallbackController

  def landing_page(conn, _params) do
    render(conn, :landing_page,
      page_title: gettext("Passwordless"),
      page_description:
        gettext(
          "More than uptime checks - catch website bugs with Playwright and never miss regressions in production again. No complex setup required. Flexible pricing."
        )
    )
  end
end
