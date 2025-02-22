defmodule PasswordlessWeb.DevRoutes do
  @moduledoc """
  Development only routes (don't use route helpers to generate paths for these routes or they'll fail in production)
  eg. instead of `~p"/dev"`, just write `/dev`
  """
  defmacro __using__(_opts \\ []) do
    quote do
      if Mix.env() in [:dev, :test] do
        scope "/" do
          pipe_through [:browser, :authenticated]

          forward "/dev/mailbox", Plug.Swoosh.MailboxPreview
        end

        scope "/dev", PasswordlessWeb do
          pipe_through [:browser, :authenticated]

          live_session :dev_session,
            on_mount: [
              {PasswordlessWeb.User.Hooks, :require_authenticated_user},
              {PasswordlessWeb.Org.Hooks, :fetch_current_org}
            ] do
            live "/", DevDashboardLive

            scope "/emails" do
              get "/", EmailTestingController, :index
              get "/sent", EmailTestingController, :sent
              get "/preview/:email_name", EmailTestingController, :preview

              post "/send_test_email/:email_name",
                   EmailTestingController,
                   :send_test_email

              get "/show/:email_name", EmailTestingController, :show_html
            end
          end
        end
      end
    end
  end
end
