defmodule Passwordless.MixProject do
  use Mix.Project

  @version "1.8.0"

  def project do
    [
      app: :passwordless,
      version: @version,
      elixir: "1.18.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        quality: :test,
        wallaby: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Passwordless.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  # Type `mix deps.update --all` to update deps (won't updated this file)
  # Type `mix hex.outdated` to see deps that can be updated
  defp deps do
    [
      # Phoenix base
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.20.0"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_seo, "~> 0.1.10"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.16"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26.2", override: true},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.6"},
      {:libcluster, "~> 3.5", only: [:dev, :prod]},
      {:flop, "~> 0.26.1"},
      {:email_checker, "~> 0.2.4"},
      {:rustler, "~> 0.36.1"},
      {:floki, "~> 0.37.0"},
      {:memoize, "~> 1.4"},

      # Emails
      {:phoenix_swoosh, "~> 1.2"},
      {:premailex, "~> 0.3"},
      {:gen_smtp, "~> 1.2"},

      # Phones
      {:ex_phone_number, "~> 0.4.5"},

      # Ecto querying / pagination
      {:query_builder, "~> 1.4"},

      # Authentication
      {:argon2_elixir, "~> 4.1"},
      {:ueberauth, "~> 0.10.8"},
      {:ueberauth_google, "~> 0.12"},

      # API
      {:open_api_spex, "~> 3.18"},

      # TOTP (2FA)
      {:nimble_totp, "~> 1.0"},
      {:eqrcode, "~> 0.2.1"},

      # Assets
      {:tailwind, "~> 0.3.1", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.2.0", sparse: "optimized", app: false, compile: false, depth: 1},

      # Observability
      {:sentry, "~> 10.8"},
      {:backpex, "~> 0.12.0"},
      {:ecto_psql_extras, "~> 0.8.7"},

      # Media
      {:image, "~> 0.47.0"},
      {:nimble_csv, "~> 1.2"},

      # Utils
      {:uniq, "~> 0.6.1"},
      {:blankable, "~> 1.0.0"},
      {:one_and_done, "~> 0.1.6"},
      {:currency_formatter, "~> 0.8"},
      {:timex, "~> 3.7"},
      {:slugify, "~> 1.3"},
      {:burnex, "~> 3.2"},
      {:faker, "~> 0.17"},
      {:redix, "~> 1.4"},
      {:corsica, "~> 2.1"},
      {:castore, "~> 1.0"},
      {:cachex, "~> 4.0"},
      {:money, "~> 1.13"},
      {:sweet_xml, "~> 0.7.4"},
      {:domainatrex, "~> 3.0"},
      {:sizeable, "~> 1.0"},
      {:crontab, "~> 1.1"},
      {:cloak_ecto, "~> 1.3"},
      {:typedstruct, "~> 0.5.3"},

      # Markdown
      {:earmark, "~> 1.4"},
      {:html_sanitize_ex, "~> 1.4"},

      # HTTP client
      {:tesla, "~> 1.9"},
      {:finch, "~> 0.18.0"},
      {:inet_cidr, "~> 1.0"},

      # Testing
      {:wallaby, "~> 0.30", runtime: false, only: :test},
      {:mimic, "~> 1.7", only: :test},
      {:exvcr, "~> 0.15", only: :test},

      # Jobs / Cron
      {:oban, "~> 2.17"},
      {:oban_pro, "~> 1.3", repo: "oban"},
      {:oban_web, "~> 2.10", repo: "oban"},
      {:gen_stage, "~> 1.2"},

      # Locate
      {:ex_cldr, "~> 2.40"},
      {:ex_cldr_numbers, "~> 2.33"},

      # Security
      {:hammer, "~> 6.2"},
      {:hammer_plug, "~> 3.0"},
      {:hammer_backend_redis, "~> 6.1"},
      {:content_security_policy, "~> 1.0"},

      # Code quality
      {:sobelow, "~> 0.12", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:dev, :test], runtime: false},
      {:styler, "~> 0.11", only: [:dev, :test], runtime: false},
      {:sql_fmt, "~> 0.2.0"},

      # Payments
      {:stripity_stripe, "~> 3.1"},

      # AWS
      {:aws, "~> 1.0"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:ex_aws_kms, "~> 2.4"},
      {:ex_aws_ses, "~> 2.4"},
      {:ex_aws_sns, "~> 2.3"},
      {:ex_aws_secretsmanager, "~> 2.0"},
      {:aws_rds_castore, "~> 1.2"},

      # Temporary
      {:rename_project, "~> 0.1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      c: ["format_code", "compile"],
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.seed": ["run priv/repo/seeds.exs"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "tailwind backpex", "esbuild default"],
      "assets.deploy": [
        "tailwind default --minify",
        "tailwind backpex --minify",
        "esbuild default --minify",
        "phx.digest"
      ],
      # Run to check the quality of your code
      quality: [
        "format",
        "sobelow --config",
        "coveralls",
        "credo"
      ],
      update_translations: ["gettext.extract --merge"],
      format_code: ["format", "cmd cargo fmt"],

      # Unlocks unused dependencies (no longer mentioned in the mix.exs file)
      clean_mix_lock: ["deps.unlock --unused"],

      # Only run wallaby (e2e) tests
      wallaby: ["test --only feature"],
      seed: ["run priv/repo/seeds.exs"]
    ]
  end
end
