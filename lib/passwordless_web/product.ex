defmodule PasswordlessWeb.Product do
  @moduledoc false

  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  def pricing_plans,
    do: [
      %{
        kind: :free,
        title: gettext("Free"),
        description: gettext("Ideal for small projects, offering essential monitoring tools and alerting features."),
        action_text: gettext("Get started"),
        action_path: ~p"/auth/sign-up",
        features: [
          {true, "100 browser check runs"},
          {true, "1 project"},
          {true, "1 user"},
          {true, "1 week of historical data"},
          {true, "All available features"}
        ]
      },
      %{
        kind: :business,
        title: gettext("Business"),
        description: gettext("For modern development teams, providing advanced monitoring features."),
        action_text: gettext("Start free 14-day trial"),
        action_path: ~p"/auth/sign-up",
        features: [
          {true, "12,000 browser check runs"},
          {true, "10 projects"},
          {true, "25 users"},
          {true, "3 months of historical data"},
          {true, "+ $5.00 for 1,000 extra runs"}
        ]
      },
      %{
        kind: :enterprise,
        title: gettext("Enterprise"),
        description: gettext("Custom-built for large-scale teams to build, run, and scale synthetic monitoring."),
        action_text: gettext("Contact sales"),
        action_path: "mailto:#{Passwordless.config(:sales_email)}",
        features: [
          {true, "Custom amount of check runs"},
          {true, "Custom number of projects"},
          {true, "Custom number of users"},
          {true, "Custom data retention"},
          {true, "99.9% SLA"}
        ]
      }
    ]
end
