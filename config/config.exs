# General application configuration
import Config

config :passwordless,
  app_name: "Passwordless",
  business_name: "Passwordless",
  support_email: "hello@passwordless.tools",
  sales_email: "sales@passwordless.tools",
  logo_url_for_emails:
    "https://res.cloudinary.com/wickedsites/image/upload/v1643336799/petal/petal_logo_light_w5jvlg.png",
  description:
    "Passwordless introduces code-first synthetic monitoring to secure the uptime and performance of your apps and websites",
  seo_description:
    "More than uptime checks - catch website bugs with Playwright and never miss regressions in production again. No complex setup required. Flexible pricing.",
  twitter_url: "https://x.com/Passwordless",
  facebook_url: "https://www.facebook.com/profile.php?id=61570653856696",
  linkedin_url: "https://www.linkedin.com/company/livecheckio",
  github_url: "https://github.com/Passwordless",
  keywords: [
    "monitoring as code",
    "synthetic monitoring"
  ]

# Configures the repo
config :passwordless,
  ecto_repos: [Passwordless.Repo],
  generators: [timestamp_type: :utc_datetime_usec],
  migration_primary_key: [type: :uuid]

# Configures the session
config :passwordless, :session,
  salt: "N7Amr6UvJN64wB3iLstI9fwNJGAIZpVmJDxOHWVx+VtKaT3d8nTeH5UZNJxniSse",
  max_age: :timer.hours(24 * 30),
  signing_salt: "dp9YDk0w",
  encryption_salt: "9saWZiuk"

# Configures the endpoint
config :passwordless, PasswordlessWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PasswordlessWeb.ErrorHTML, json: PasswordlessWeb.ErrorJSON],
    layout: {PasswordlessWeb.Layouts, :error},
    root_layout: {PasswordlessWeb.Layouts, :root}
  ],
  pubsub_server: Passwordless.PubSub,
  live_view: [signing_salt: "Fd8SWPu3"]

# Configures AWS
config :ex_aws,
  region: "us-east-1",
  http_client: Passwordless.ExAwsClient

# Configures Oban
config :passwordless, Oban,
  repo: Passwordless.Repo,
  queues: [
    default: 100,
    mailer: [local_limit: 10, global_limit: 20],
    executor: [local_limit: 10, global_limit: 20],
    scheduler: [local_limit: 10, global_limit: 10],
    statistics: [local_limit: 10, global_limit: 10]
  ],
  engine: Oban.Pro.Engines.Smart,
  notifier: Oban.Notifiers.PG,
  plugins: [
    Oban.Pro.Plugins.DynamicLifeline,
    Oban.Pro.Plugins.DynamicPrioritizer,
    Oban.Pro.Plugins.DynamicPartitioner,
    {Oban.Pro.Plugins.DynamicCron, crontab: []}
  ]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
config :passwordless, Passwordless.Mailer, adapter: Swoosh.Adapters.Local

# Configures the cache
config :passwordless, :cache, adapter: Cache.InMemory

# Configures the object storage
config :passwordless, :storage, adapter: Storage.Local

# Configures the media uploader to local
config :passwordless, :media_upload, adapter: Passwordless.Media.Upload.Local

# Configures the media uploader to local
config :passwordless, :audience_import, bucket: ""

# Configures the thumbnail storage for templates
config :passwordless, :template_thumbnail, bucket: ""

config :passwordless, :media,
  buckets: [
    embedded: "blah",
    attached: "blah"
  ]

config :passwordless, :emails,
  support: [
    name: "Passwordless",
    email: "noreply@support.getlivecheck.com",
    reply_to: "hello@passwordless.tools",
    reply_to_name: "Passwordless Support"
  ],
  alerts: [
    name: "Passwordless Alert",
    email: "noreply@alerts.getlivecheck.com",
    reply_to: "hello@passwordless.tools",
    reply_to_name: "Passwordless Support"
  ]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.23.0",
  default: [
    args: ~w(
      js/app.ts
      --bundle
      --target=esnext
      --outdir=../priv/static/assets
      --external:/fonts/*
      --external:/images/*
      --loader:.ttf=dataurl
      --loader:.woff=dataurl
      --loader:.woff2=dataurl
    ),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :passwordless,
       :error_translator_function,
       {PasswordlessWeb.CoreComponents, :translate_error}

config :tailwind,
  version: "3.4.17",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ],
  backpex: [
    args: ~w(
    --config=tailwind.backpex.config.js
    --output=../priv/static/assets/backpex.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Specify which languages you support
# To create .po files for a language run `mix gettext.merge priv/gettext --locale fr`
# (fr is France, change to whatever language you want - make sure it's included in the locales config below)
config :passwordless, PasswordlessWeb.Gettext, allowed_locales: ~w(en)

config :passwordless, :language_options, [
  %{locale: "en", flag: "🇬🇧", label: "English"}
]

# Social login providers
config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
  ]

# Setup Contentful
config :passwordless, :contentful,
  space_id: "p33ulv4i0ung",
  environment: "master",
  access_token: {:system, "CONTENTFUL_ACCESS_TOKEN"}

config :passwordless, :translation_helper_module, PasswordlessWeb.PetalFrameworkTranslations

# Reduce XSS risks by declaring which dynamic resources are allowed to load
# If you use any CDNs, whitelist them here.
# Policy struct: https://github.com/mbramson/content_security_policy/blob/master/lib/content_security_policy/policy.ex
# Read more about the options: https://content-security-policy.com
# Note that we use unsafe-eval because Alpine JS requires it :( (see https://alpinejs.dev/advanced/csp)
config :passwordless, :content_security_policy, %{
  default_src: [
    "'unsafe-inline'",
    "'unsafe-eval'",
    "'self'",
    "data:",
    "blob:",
    "https://rsms.me",
    "*.amazonaws.com",
    "https://*.google-analytics.com",
    "https://*.analytics.google.com",
    "https://*.googletagmanager.com",
    "https://*.googleapis.com",
    "https://*.gstatic.com",
    "https://*.cloudflare.com",
    "*.iubenda.com",
    "*.fillout.com",
    "*.savvycal.com",
    "https://*.atlas.so",
    "https://*.jsdelivr.net",
    "https://*.passwordless.tools",
    "https://*.featurebase.app"
  ],
  connect_src:
    case Mix.env() do
      :prod ->
        [
          "wss://#{System.get_env("PHX_HOST") || "passwordless.tools"}",
          "https://#{System.get_env("PHX_HOST") || "passwordless.tools"}"
        ]

      _ ->
        [
          "ws://localhost:#{String.to_integer(System.get_env("PORT") || "4000")}",
          "http://localhost:#{String.to_integer(System.get_env("PORT") || "4000")}"
        ]
    end ++
      [
        "https://*.google-analytics.com",
        "https://*.analytics.google.com",
        "https://*.googletagmanager.com",
        "https://*.googleapis.com",
        "https://*.gstatic.com",
        "https://*.cloudflare.com",
        "*.iubenda.com",
        "*.fillout.com",
        "*.savvycal.com",
        "wss://*.atlas.so",
        "https://*.atlas.so",
        "https://*.jsdelivr.net",
        "https://*.abstractapi.com",
        "https://*.featurebase.app"
      ],
  img_src: [
    "*",
    "'self'",
    "data:",
    "https:"
  ],
  frame_src:
    [
      "https://*.passwordless.tools",
      "*.fillout.com",
      "*.savvycal.com",
      "savvycal.com",
      "https://*.featurebase.app"
    ] ++
      case Mix.env() do
        :prod ->
          []

        _ ->
          [
            "http://localhost:#{String.to_integer(System.get_env("PORT") || "4000")}"
          ]
      end
}

config :flop, repo: Passwordless.Repo, default_limit: 10
config :tesla, :adapter, {Tesla.Adapter.Finch, name: Passwordless.Finch}

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

config :passwordless, :trial_period_days, 14

config :passwordless, :billing_provider, Passwordless.Billing.Providers.Stripe

config :passwordless, :billing_plans, [
  %{
    id: "business",
    name: "Business",
    description: "The Business plan",
    features: [
      "Essential feature 1",
      "Essential feature 2",
      "Essential feature 3"
    ],
    trial_days: 14,
    allow_promotion_codes: true,
    prices: [
      %{
        id: :contacts,
        name: "Contacts",
        price: "price_1NLhPDIWVkWpNCp7trePDpmi1",
        model: :usage_based,
        interval: "month",
        usage_type: :licensed,
        tiers: [
          %{from: 1_000, to: 5_000, amount: 4900},
          %{from: 5_001, to: 10_000, amount: 9900},
          %{from: 10_001, to: 15_000, amount: 14_900},
          %{from: 15_001, to: 25_000, amount: 19_900},
          %{from: 25_001, to: 50_000, amount: 24_900},
          %{from: 50_001, to: 100_000, amount: 39_900}
        ]
      },
      %{
        id: :contacts,
        name: "Contacts",
        price: "price_1NLhPDIWVkWpNCp7trePDpmi2",
        model: :usage_based,
        interval: "year",
        usage_type: :licensed,
        tiers: [
          %{from: 1_000, to: 5_000, amount: 4900},
          %{from: 5_001, to: 10_000, amount: 9900},
          %{from: 10_001, to: 15_000, amount: 14_900},
          %{from: 15_001, to: 25_000, amount: 19_900},
          %{from: 25_001, to: 50_000, amount: 24_900},
          %{from: 50_001, to: 100_000, amount: 39_900}
        ]
      },
      %{
        id: :"transactional-emails",
        name: "Transactional Emails",
        price: "price_1NLhPDIWVkWpNCp7trePDpmi3",
        model: :usage_based,
        interval: "month",
        usage_type: :metered,
        rate: %{
          amount: 2000,
          cost: 1
        }
      }
    ]
  }
]

config :passwordless, :browser,
  on_demand: false,
  no_sandbox: true,
  debug_browser_protocol: true

config :passwordless, :languages,
  af: "Afghanistan",
  ax: "Aland Islands",
  al: "Albania",
  dz: "Algeria",
  as: "American Samoa",
  ad: "Andorra",
  ao: "Angola",
  ai: "Anguilla",
  aq: "Antarctica",
  ag: "Antigua and Barbuda",
  ar: "Argentina",
  am: "Armenia",
  aw: "Aruba",
  "sh-ac": "Ascension Island",
  asean: "Association of Southeast Asian Nations",
  au: "Australia",
  at: "Austria",
  az: "Azerbaijan",
  bs: "Bahamas",
  bh: "Bahrain",
  bd: "Bangladesh",
  bb: "Barbados",
  "es-pv": "Basque Country",
  by: "Belarus",
  be: "Belgium",
  bz: "Belize",
  bj: "Benin",
  bm: "Bermuda",
  bt: "Bhutan",
  bo: "Bolivia",
  bq: "Bonaire, Sint Eustatius and Saba",
  ba: "Bosnia and Herzegovina",
  bw: "Botswana",
  bv: "Bouvet Island",
  br: "Brazil",
  io: "British Indian Ocean Territory",
  bn: "Brunei Darussalam",
  bg: "Bulgaria",
  bf: "Burkina Faso",
  bi: "Burundi",
  cv: "Cabo Verde",
  kh: "Cambodia",
  cm: "Cameroon",
  ca: "Canada",
  ic: "Canary Islands",
  "es-ct": "Catalonia",
  ky: "Cayman Islands",
  cf: "Central African Republic",
  cefta: "Central European Free Trade Agreement",
  td: "Chad",
  cl: "Chile",
  cn: "China",
  cx: "Christmas Island",
  cp: "Clipperton Island",
  cc: "Cocos (Keeling) Islands",
  co: "Colombia",
  km: "Comoros",
  ck: "Cook Islands",
  cr: "Costa Rica",
  hr: "Croatia",
  cu: "Cuba",
  cw: "Curaçao",
  cy: "Cyprus",
  cz: "Czech Republic",
  ci: "Côte d'Ivoire",
  cd: "Democratic Republic of the Congo",
  dk: "Denmark",
  dg: "Diego Garcia",
  dj: "Djibouti",
  dm: "Dominica",
  do: "Dominican Republic",
  eac: "East African Community",
  ec: "Ecuador",
  eg: "Egypt",
  sv: "El Salvador",
  "gb-eng": "England",
  gq: "Equatorial Guinea",
  er: "Eritrea",
  ee: "Estonia",
  sz: "Eswatini",
  et: "Ethiopia",
  eu: "Europe",
  fk: "Falkland Islands",
  fo: "Faroe Islands",
  fm: "Federated States of Micronesia",
  fj: "Fiji",
  fi: "Finland",
  fr: "France",
  gf: "French Guiana",
  pf: "French Polynesia",
  tf: "French Southern Territories",
  ga: "Gabon",
  "es-ga": "Galicia",
  gm: "Gambia",
  ge: "Georgia",
  de: "Germany",
  gh: "Ghana",
  gi: "Gibraltar",
  gr: "Greece",
  gl: "Greenland",
  gd: "Grenada",
  gp: "Guadeloupe",
  gu: "Guam",
  gt: "Guatemala",
  gg: "Guernsey",
  gn: "Guinea",
  gw: "Guinea-Bissau",
  gy: "Guyana",
  ht: "Haiti",
  hm: "Heard Island and McDonald Islands",
  va: "Holy See",
  hn: "Honduras",
  hk: "Hong Kong",
  hu: "Hungary",
  is: "Iceland",
  in: "India",
  id: "Indonesia",
  ir: "Iran",
  iq: "Iraq",
  ie: "Ireland",
  im: "Isle of Man",
  il: "Israel",
  it: "Italy",
  jm: "Jamaica",
  jp: "Japan",
  je: "Jersey",
  jo: "Jordan",
  kz: "Kazakhstan",
  ke: "Kenya",
  ki: "Kiribati",
  xk: "Kosovo",
  kw: "Kuwait",
  kg: "Kyrgyzstan",
  la: "Laos",
  lv: "Latvia",
  arab: "League of Arab States",
  lb: "Lebanon",
  ls: "Lesotho",
  lr: "Liberia",
  ly: "Libya",
  li: "Liechtenstein",
  lt: "Lithuania",
  lu: "Luxembourg",
  mo: "Macau",
  mg: "Madagascar",
  mw: "Malawi",
  my: "Malaysia",
  mv: "Maldives",
  ml: "Mali",
  mt: "Malta",
  mh: "Marshall Islands",
  mq: "Martinique",
  mr: "Mauritania",
  mu: "Mauritius",
  yt: "Mayotte",
  mx: "Mexico",
  md: "Moldova",
  mc: "Monaco",
  mn: "Mongolia",
  me: "Montenegro",
  ms: "Montserrat",
  ma: "Morocco",
  mz: "Mozambique",
  mm: "Myanmar",
  na: "Namibia",
  nr: "Nauru",
  np: "Nepal",
  nl: "Netherlands",
  nc: "New Caledonia",
  nz: "New Zealand",
  ni: "Nicaragua",
  ne: "Niger",
  ng: "Nigeria",
  nu: "Niue",
  nf: "Norfolk Island",
  kp: "North Korea",
  mk: "North Macedonia",
  "gb-nir": "Northern Ireland",
  mp: "Northern Mariana Islands",
  no: "Norway",
  om: "Oman",
  pc: "Pacific Community",
  pk: "Pakistan",
  pw: "Palau",
  pa: "Panama",
  pg: "Papua New Guinea",
  py: "Paraguay",
  pe: "Peru",
  ph: "Philippines",
  pn: "Pitcairn",
  pl: "Poland",
  pt: "Portugal",
  pr: "Puerto Rico",
  qa: "Qatar",
  cg: "Republic of the Congo",
  ro: "Romania",
  ru: "Russia",
  rw: "Rwanda",
  re: "Réunion",
  bl: "Saint Barthélemy",
  "sh-hl": "Saint Helena",
  sh: "Saint Helena, Ascension and Tristan da Cunha",
  kn: "Saint Kitts and Nevis",
  lc: "Saint Lucia",
  mf: "Saint Martin",
  pm: "Saint Pierre and Miquelon",
  vc: "Saint Vincent and the Grenadines",
  ws: "Samoa",
  sm: "San Marino",
  st: "Sao Tome and Principe",
  sa: "Saudi Arabia",
  "gb-sct": "Scotland",
  sn: "Senegal",
  rs: "Serbia",
  sc: "Seychelles",
  sl: "Sierra Leone",
  sg: "Singapore",
  sx: "Sint Maarten",
  sk: "Slovakia",
  si: "Slovenia",
  sb: "Solomon Islands",
  so: "Somalia",
  za: "South Africa",
  gs: "South Georgia and the South Sandwich Islands",
  kr: "South Korea",
  ss: "South Sudan",
  es: "Spain",
  lk: "Sri Lanka",
  ps: "State of Palestine",
  sd: "Sudan",
  sr: "Suriname",
  sj: "Svalbard and Jan Mayen",
  se: "Sweden",
  ch: "Switzerland",
  sy: "Syria",
  tw: "Taiwan",
  tj: "Tajikistan",
  tz: "Tanzania",
  th: "Thailand",
  tl: "Timor-Leste",
  tg: "Togo",
  tk: "Tokelau",
  to: "Tonga",
  tt: "Trinidad and Tobago",
  "sh-ta": "Tristan da Cunha",
  tn: "Tunisia",
  tm: "Turkmenistan",
  tc: "Turks and Caicos Islands",
  tv: "Tuvalu",
  tr: "Türkiye",
  ug: "Uganda",
  ua: "Ukraine",
  ae: "United Arab Emirates",
  gb: "United Kingdom",
  un: "United Nations",
  um: "United States Minor Outlying Islands",
  us: "United States of America",
  xx: "Unknown",
  uy: "Uruguay",
  uz: "Uzbekistan",
  vu: "Vanuatu",
  ve: "Venezuela",
  vn: "Vietnam",
  vg: "Virgin Islands (British)",
  vi: "Virgin Islands (U.S.)",
  "gb-wls": "Wales",
  wf: "Wallis and Futuna",
  eh: "Western Sahara",
  ye: "Yemen",
  zm: "Zambia",
  zw: "Zimbabwe"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
