defmodule PasswordlessWeb.Product do
  @moduledoc false

  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  def testimonials,
    do: [
      %{
        name: "Marcin Praski",
        title: "CEO, Passwordless",
        content:
          "With Passwordless, we have successfully reduced test building time by an impressive 100%, saving an average of 60 minutes per day. This time-saving benefit enables our team to focus on other critical tasks and enhances overall productivity.",
        image_src: "https://praski.dev/profile.webp"
      },
      %{
        name: "Marcin Praski",
        title: "CEO, Passwordless",
        content:
          "Passwordless saved us 2-3 hours after each deployment. We were surprised how easy it is to add custom logic to each test. Even though the features provided cover 80% of our use cases, when we needed to execute custom logic around them - it's super easy.",
        image_src: "https://praski.dev/profile.webp"
      },
      %{
        name: "Marcin Praski",
        title: "CEO, Passwordless",
        content:
          "In two days, we managed to automate test cases that took us weeks to write up and execute using other software. It is easy to use, yet can still perform advanced testing should the tester want to.",
        image_src: "https://praski.dev/profile.webp"
      },
      %{
        name: "Marcin Praski",
        title: "CEO, Passwordless",
        content:
          "Stop wasting your time on complicated and expensive tools. Create end-to-end tests effortlessly with a reliable test recorder in less than 5 minutes.",
        image_src: "https://praski.dev/profile.webp"
      }
    ]

  def features,
    do: [
      %{
        to: ~p"/product",
        title: gettext("Browser checks"),
        description: gettext("Convert your Playwright tests into automated incident detectors, with zero configuration."),
        image_path: ~p"/images/landing_page/feature-1.webp",
        image_class: "rounded-lg shadow-4 mt-2"
      },
      %{
        to: ~p"/product",
        title: gettext("Automated runs"),
        description: gettext("Automatically set up and maintain monitoring. Minimize manual work, save time and money."),
        image_path: ~p"/images/landing_page/feature-2.webp",
        image_class: "scale-[2.6] origin-bottom"
      },
      %{
        to: ~p"/product",
        title: gettext("Uptime monitoring"),
        description:
          gettext("When a test fails or degrades, we'll notify you before your users experience any downtime."),
        image_path: ~p"/images/landing_page/feature-6.webp"
      },
      %{
        to: ~p"/product",
        title: gettext("Historical data"),
        description: gettext("We'll help you track performance, security and regressions of your website over time."),
        image_path: ~p"/images/landing_page/feature-4.webp",
        image_class: "rounded-lg shadow-1 md:scale-2 xl:scale-[1.15] origin-top-right",
        reverse: true,
        class: "xl:col-span-2"
      },
      %{
        to: ~p"/product",
        title: gettext("Instant notifications"),
        description: gettext("Get notified instantly by phone call, SMS, email or Slack if your website is compromised."),
        image_path: ~p"/images/landing_page/feature-5.webp",
        image_class: "rounded-lg shadow-4 scale-[1.6] origin-top-left"
      }
    ]

  def minor_features,
    do: [
      %{
        title: gettext("Platform"),
        description: gettext("Run your Playwright tests from around the globe, at scale. No setup required."),
        icon: "custom-categories"
      },
      %{
        title: gettext("Dashboard"),
        description: gettext("Monitor all your websites in real time, get continuous test coverage."),
        icon: "custom-dashboard"
      },
      %{
        title: gettext("Alerts"),
        description: gettext("Get notified instantly when an incident is detected via SMS, email or Slack."),
        icon: "custom-filter"
      },
      %{
        title: gettext("Security"),
        description: gettext("Your code and data is secure with us. We adhere to industry standards."),
        icon: "custom-focus-frame"
      }
    ]

  def benefit_quotas,
    do: [
      %{number: "8 hrs", description: "Time saved on manual QA monthly"},
      %{number: "10 min", description: "Average time to incident response"},
      %{number: "$1200", description: "Costs saved on QA efforts monthly"}
    ]

  def benefit_highlights,
    do: [
      %{
        name: "As QA",
        image: ~p"/images/landing_page/highlight-1.svg",
        description:
          "Automate your testing with our scheduled geo-distributed monitors. Forget about flaky tests and slow tools."
      },
      %{
        name: "As Developer",
        image: ~p"/images/landing_page/highlight-2.svg",
        description:
          "Focus on code rather than testing. Get instant feedback in our cloud IDE, and let us take care of orchestration."
      },
      %{
        name: "As Product Manager",
        image: ~p"/images/landing_page/highlight-3.svg",
        description: "Catch bugs before your clients do, invite your team and guard the critical paths of your products."
      }
    ]

  def pricing_modes,
    do: [%{id: :yearly, label: gettext("Annually"), modifier: "-20%"}, %{id: :monthly, label: gettext("Monthly")}]

  def pricing_plans, do: [gettext("Free"), gettext("Business")]

  def pricing_plans2,
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

  def pricing_plan_features,
    do: [
      %{
        title: gettext("Usage"),
        rows: [
          ["Users", "1", "20"],
          [{"Browser checks", "The interactive monitor that periodically checks your website"}, "Unlimited", "Unlimited"],
          [
            {"Browser check runs", "You can schedule your Passwordlesss in regular intervals for maximum test coverage"},
            "1,000 / month",
            "12,000 / month"
          ],
          [{"Status Pages", "You can share the uptime detected by Passwordlesss via status pages"}, "1", "5"],
          [
            {"Retention Policy", "The time for which we keep your uptime & website performance data"},
            "1 week",
            "12 months"
          ]
        ]
      },
      %{
        title: "Monitoring",
        rows: [
          [
            {"Cloud IDE", "A user-friendly code environment where you can design and debug your Passwordlesss"},
            true,
            true
          ],
          [{"Screenshots", "Every step of your test is screenshotted"}, true, true],
          [
            {"Instant Replay", "Watch a step-by-step recording of your test runs. See exact point of failure"},
            true,
            true
          ],
          [
            {"Network / Console Logs", "View exact logs printed in the browser's console during your test runs"},
            true,
            true
          ],
          [{"Environments", "You can share variables & secrets across Passwordlesss"}, false, true],
          [
            {"Debugging", "How many minutes per month you can run your checks in the Cloud IDE"},
            "10 minutes / month",
            "unlimited"
          ]
        ]
      },
      %{
        title: "Alerts",
        rows: [
          [{"Alert Builder", "Decide when and why you want to be notified"}, true, true],
          ["Email Notifications", false, true],
          ["SMS Notifications", false, true],
          ["Slack Notifications", false, true]
        ]
      },
      %{
        title: "Status Pages",
        rows: [
          [{"Drag-and-drop Builder", "Compose your status page out of your Passwordlesss"}, true, true],
          ["Page Preview", true, true],
          ["Public Pages", false, true],
          ["Private Pages", false, true],
          ["Password-protected Pages", false, true]
        ]
      },
      %{title: gettext("Security"), rows: [["2FA", true, true]]},
      %{title: gettext("Support"), rows: [["Normal support", true, true], ["Priority support", false, true]]}
    ]
end
