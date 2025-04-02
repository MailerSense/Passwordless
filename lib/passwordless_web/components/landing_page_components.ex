defmodule PasswordlessWeb.LandingPageComponents do
  @moduledoc """
  A set of components for use in a landing page.
  """

  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Button
  import PasswordlessWeb.Components.Container
  import PasswordlessWeb.Components.Icon
  import PasswordlessWeb.Components.Link
  import PasswordlessWeb.Components.PageComponents
  import PasswordlessWeb.PricingPageComponents

  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]
  attr :current_user, :map, default: nil

  def hero(assigns) do
    ~H"""
    <section class="bg-slate-900 border-t border-t-1 border-slate-950" role="banner">
      <.hero_text max_width={@max_width} current_user={@current_user} />
      <.hero_image max_width={@max_width} />
    </section>
    """
  end

  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]
  attr :current_user, :map, default: nil

  def hero_text(assigns) do
    ~H"""
    <.container max_width={@max_width} class="flex flex-col items-center">
      <div class="flex flex-col items-center max-w-4xl py-8 md:py-16">
        <.promo_banner
          to={~p"/active-development"}
          icon="remix-alert-fill"
          icon_class="h-4 w-4"
          color_primary="bg-warning-300"
          color_secondary="bg-warning-100"
          class="mb-6"
          content={gettext("We're in development")}
        />
        <!--<.promo_banner
          to={~p"/auth/sign-up"}
          icon="remix-discord"
          icon_class="h-4"
          class="mb-6 md:mb-3"
          content="Join our Discord Community"
        />-->
        <h1 class="text-white font-display font-bold text-4xl sm:text-5xl md:text-6xl md:leading-[74px] tracking-tight text-center mb-6">
          Strong Passwordless authentication in minutes
        </h1>
        <p class="inline-block text-xl text-white text-center md:max-w-2xl mb-6 sm:mb-10 leading-[30px]">
          Run
          <img
            src={static_url(PasswordlessWeb.Endpoint, ~p"/images/landing_page/playwright-logo.svg")}
            alt={gettext("Playwright")}
            title={gettext("Playwright")}
            class="inline h-4 mr-1 scale-[1.2]"
          /><strong>Playwright</strong>
          tests 24/7 and continuously monitor your apps.
          Simplify your test automation setup with Passwordless.
        </p>
        <div class="flex flex-col sm:flex-row gap-4 items-center">
          <.button
            size="lg"
            title={if @current_user, do: gettext("Open App"), else: gettext("Start Automating")}
            to={if @current_user, do: ~p"/app/home", else: ~p"/auth/sign-up"}
            link_type="a"
          />
          <div class="hidden sm:block">
            <.button
              size="lg"
              title={gettext("Book a Demo")}
              variant="outline"
              with_icon
              to={~p"/book-demo"}
              link_type="a"
            >
              {gettext("Book a Demo")}<.icon name="remix-arrow-right-line" class="w-6 h-6 " />
            </.button>
          </div>
        </div>
      </div>
    </.container>
    """
  end

  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]
  attr :class, :any, default: nil

  def hero_image(assigns) do
    ~H"""
    <div class={[
      @class,
      "px-4 md:px-16 lg:px-0 h-[175px] sm:h-[300px] md:h-[350px] lg:h-[450px] relative overflow-hidden"
    ]}>
      <img
        src={static_url(PasswordlessWeb.Endpoint, ~p"/images/landing_page/chart-line.svg")}
        alt={Passwordless.config(:app_name)}
        title={Passwordless.config(:app_name)}
        class="absolute left-0 bottom-0 z-0 object-fill w-full"
        loading="lazy"
      />

      <div class="rounded-3xl p-4 bg-slate-950 max-w-[900px] xl:max-w-[1000px] mx-auto relative z-1">
        <.a to={~p"/product"} title={gettext("Learn more about Passwordless")}>
          <img
            src={static_url(PasswordlessWeb.Endpoint, ~p"/images/landing_page/hero.webp")}
            alt={gettext("Uptime Monitoring Service Made For Developers")}
            title={Passwordless.config(:app_name)}
            class="rounded-xl"
            fetchpriority="high"
            width="968"
            height="689"
          />
        </.a>
      </div>
    </div>
    """
  end

  attr :image_src, :string, required: true
  attr :image_title, :string, required: true
  attr :image_alt, :string, required: true
  attr :image_width, :integer, required: true
  attr :image_height, :integer, required: true
  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]

  def hero_image_header(assigns) do
    ~H"""
    <div class="px-4 md:px-16 lg:px-0 h-[150px] sm:h-[250px] md:h-[300px] lg:h-[380px] relative overflow-hidden bg-slate-900">
      <img
        src={static_url(PasswordlessWeb.Endpoint, ~p"/images/landing_page/chart-line.svg")}
        alt={Passwordless.config(:app_name)}
        title={Passwordless.config(:app_name)}
        class="absolute left-0 bottom-0 z-0 object-fill w-full"
        loading="lazy"
      />

      <div class="rounded-3xl p-4 bg-slate-950 max-w-[900px] xl:max-w-[1000px] mx-auto relative z-1">
        <img
          src={static_url(PasswordlessWeb.Endpoint, @image_src)}
          alt={@image_alt}
          title={@image_title}
          class="rounded-xl"
          fetchpriority="high"
          width={@image_width}
          height={@image_height}
        />
      </div>
    </div>
    """
  end

  attr :badge, :string, default: nil
  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil

  def hero_header(assigns) do
    ~H"""
    <section class={[
      "flex flex-col items-center py-8 md:py-16 px-4 md:px-0 border-t border-t-1 border-slate-950",
      "bg-slate-900",
      @class
    ]}>
      <badge class="text-center text-primary-300 text-xs font-semibold uppercase mb-2">
        {@badge}
      </badge>
      <h1 class="text-white text-center text-3xl md:text-5xl font-semibold font-display mb-4">
        {@title}
      </h1>
      <h4 class="text-white/60 text-center text-lg md:text-xl font-normal font-display">
        {Phoenix.HTML.raw(@subtitle)}
      </h4>
    </section>
    """
  end

  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]
  attr :current_user, :map, default: nil

  slot :inner_block, required: false

  def hero_error(assigns) do
    ~H"""
    <section class="bg-slate-900" role="banner">
      <div class="flex flex-col items-between h-full">
        {render_slot(@inner_block)}
        <div class="px-4 md:px-16 lg:px-0 h-[200px] sm:h-[300px] md:h-[350px] lg:h-[500px] relative overflow-hidden mt-auto">
          <img
            src={static_url(PasswordlessWeb.Endpoint, ~p"/images/landing_page/chart-line.svg")}
            alt={Passwordless.config(:app_name)}
            title={Passwordless.config(:app_name)}
            class="absolute left-0 bottom-0 z-0 object-fill w-full"
            loading="lazy"
          />

          <div class="rounded-3xl p-4 bg-slate-950 max-w-[900px] xl:max-w-[1000px] mx-auto relative z-1">
            <img
              src={static_url(PasswordlessWeb.Endpoint, ~p"/images/landing_page/hero.webp")}
              alt={gettext("Uptime Monitoring Service Made For Developers")}
              title={Passwordless.config(:app_name)}
              class="rounded-xl"
              fetchpriority="high"
              width="968"
              height="689"
            />
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :badge, :string, default: nil
  attr :title, :string, default: nil
  attr :class, :any, default: nil

  def area_header(assigns) do
    ~H"""
    <div class={["flex flex-col items-center", @class]}>
      <badge
        :if={@badge}
        class="text-center text-slate-500 dark:text-white/60 text-xs font-semibold uppercase mb-2"
      >
        {@badge}
      </badge>
      <h2 class="text-slate-900 dark:text-white text-center text-3xl md:text-5xl font-semibold font-display">
        {@title}
      </h2>
    </div>
    """
  end

  attr :badge, :string, default: nil
  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil

  def area_wide_header(assigns) do
    ~H"""
    <div class={["flex flex-col items-center", @class]}>
      <badge class="text-center text-slate-500 text-xs font-semibold uppercase mb-2">{@badge}</badge>
      <h1 class="text-slate-900 text-center text-4xl md:text-5xl font-semibold font-display mb-4">
        {@title}
      </h1>
      <h4 class="text-slate-500 text-center text-xl font-normal font-display">
        {@subtitle}
      </h4>
    </div>
    """
  end

  attr :rest, :global
  attr :class, :string, default: nil, doc: "the class to add to this element"
  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]

  attr :features, :list,
    default: [],
    doc: "A list of features, which are maps with the keys :icon (a HeroiconV1), :title and :description"

  attr :minor_features, :list,
    default: [],
    doc: "A list of features, which are maps with the keys :icon (a HeroiconV1), :title and :description"

  def product_features(assigns) do
    ~H"""
    <.area pad_top={false} container={true} {@rest}>
      <.logo_cloud />
      <div class="flex flex-col py-10 md:py-[124px] gap-12">
        <.area_header badge={gettext("Features")} title={gettext("Test Automation + Monitoring")} />
        <div class="grid gap-8 grid-cols-1 md:grid-cols-2 xl:grid-cols-3">
          <.feature_card :for={feature <- @features} {feature} />
        </div>

        <div class="grid gap-12 grid-cols-1 sm:grid-cols-2 md:grid-cols-4 my-12">
          <div :for={feature <- @minor_features} class="flex flex-col">
            <.icon name={feature.icon} class="w-8 h-8 mb-4 text-slate-900" />
            <h4 class="text-slate-900 text-lg font-semibold mb-[10px]">{feature.title}</h4>
            <h5 class="text-slate-600 text-sm font-normal leading-tight">{feature.description}</h5>
          </div>
        </div>
      </div>
    </.area>
    """
  end

  attr :rest, :global
  attr :class, :string, default: nil, doc: "the class to add to this element"

  attr :features, :list,
    default: [],
    doc: "A list of features, which are maps with the keys :icon (a HeroiconV1), :title and :description"

  attr :minor_features, :list,
    default: [],
    doc: "A list of features, which are maps with the keys :icon (a HeroiconV1), :title and :description"

  def product_major_features(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class={["flex flex-col py-12 gap-12", @class]} {@rest}>
        <.area_header badge={gettext("Features")} title={gettext("What makes us different")} />
        <div class="grid gap-8 grid-cols-1 md:grid-cols-2 xl:grid-cols-3">
          <.feature_card :for={feature <- @features} {feature} />
        </div>
      </div>

      <div class="grid gap-12 grid-cols-1 sm:grid-cols-2 md:grid-cols-4 my-12">
        <div :for={feature <- @minor_features} class="flex flex-col">
          <.icon name={feature.icon} class="w-8 h-8 mb-4 text-slate-900" />
          <h4 class="text-slate-900 text-lg font-semibold mb-[10px]">{feature.title}</h4>
          <h5 class="text-slate-600 text-sm font-normal leading-tight">{feature.description}</h5>
        </div>
      </div>
    </div>
    """
  end

  attr :rest, :global
  attr :class, :string, default: nil, doc: "the class to add to this element"
  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]

  attr :quotas, :list,
    default: [],
    doc: "A list of features, which are maps with the keys :icon (a HeroiconV1), :title and :description"

  attr :highligts, :list,
    default: [],
    doc: "A list of features, which are maps with the keys :icon (a HeroiconV1), :title and :description"

  def benefits(assigns) do
    ~H"""
    <.area pad_top={false} container={true} {@rest}>
      <div class="flex flex-col pt-16 md:pt-[124px] gap-12">
        <.area_header badge={gettext("Why Choose Us")} title={gettext("Release with confidence")} />
        <div class="flex flex-col gap-12">
          <div class={["grid gap-5 grid-cols-1 md:grid-cols-2 xl:grid-cols-3"]}>
            <article
              :for={highlight <- @highligts}
              class="flex flex-col justify-between p-8 bg-slate-900 rounded-xl gap-8"
            >
              <img
                src={static_url(PasswordlessWeb.Endpoint, highlight.image)}
                alt={highlight.name}
                title={highlight.name}
                class="w-[100px] h-[100px]"
              />
              <div class="flex flex-col gap-4">
                <h3 class="text-white text-2xl font-semibold">{highlight.name}</h3>
                <p class="text-white/60 text-base font-normal">
                  {highlight.description}
                </p>
              </div>
            </article>
          </div>

          <div class="grid gap-8 lg:gap-[140px] grid-cols-1 lg:grid-cols-2">
            <h3 class="text-slate-900 text-3xl font-semibold font-display leading-[38px]">
              We offer more opportunities for an affordable price. Save time and money with our automated incident detection.
            </h3>
            <div class="flex flex-col gap-6">
              <p class="text-slate-600 text-xl font-normal leading-[30px]">
                Incidents happen even to the best of us. Our solution will augment your QA efforts to ensure bugs are caught before your users notice them!
              </p>
              <span class="flex items-center gap-2">
                <p class="text-slate-600 text-xl font-normal leading-[30px]">
                  We monitor your websites from around the globe
                </p>
                <.icon name="remix-global-line" class="w-6 h-6 text-slate-600" />
              </span>
            </div>
          </div>

          <div class={[
            "grid gap-12 md:gap-5 grid-cols-1 py-16 md:py-20 lg:grid-cols-3 border-t border-slate-200"
          ]}>
            <div :for={quota <- @quotas} class="flex flex-col items-center gap-2 md:gap-6">
              <h2 class="text-slate-900 text-center text-5xl md:text-7xl font-semibold font-display md:leading-[90px]">
                {quota.number}
              </h2>
              <p class="text-center text-slate-600">
                {quota.description}
              </p>
            </div>
          </div>
        </div>
      </div>
    </.area>
    """
  end

  attr :lazy_load, :boolean, default: true

  def logo_cloud(assigns) do
    files = [
      ~p"/images/companies/Company logo-1.svg",
      ~p"/images/companies/Company logo-2.svg",
      ~p"/images/companies/Company logo-3.svg",
      ~p"/images/companies/Company logo-4.svg",
      ~p"/images/companies/Company logo-5.svg"
    ]

    assigns = assign(assigns, files: files)

    ~H"""
    <div class="py-8 md:py-16 flex justify-center items-center gap-8 overflow-hidden">
      <img
        :for={file <- @files}
        src={static_url(PasswordlessWeb.Endpoint, file)}
        alt={file}
        title={file}
        class="h-10"
        loading={if @lazy_load, do: "lazy", else: "eager"}
      />
    </div>
    """
  end

  attr :title, :string, default: "Testimonials"
  attr :testimonials, :list, doc: "A list of maps with the keys: content, image_src, name, title"
  attr :max_width, :string, default: "lg", values: ["sm", "md", "lg", "xl", "full"]

  def testimonials(assigns) do
    ~H"""
    <section class="flex flex-col py-10 md:py-[124px] gap-12">
      <.area_header
        badge={gettext("What everyone is saying")}
        title={gettext("Trusted by professionals")}
      />
      <div class={[
        "relative flex pb-4",
        "before:bg-linear-to-r before:z-10 before:absolute before:w-32 md:before:w-64 xl:before:w-[300px] before:top-0 before:bottom-0 before:pointer-events-none",
        "after:bg-linear-to-l after:z-10 after:absolute after:w-32 md:after:w-64 xl:after:w-[300px] after:top-0 after:bottom-0 after:right-0 after:pointer-events-none",
        "from-white to-transparent"
      ]}>
        <div
          class="flex items-center px-24 gap-6 overflow-x-auto no-scrollbar"
          x-data="{
            scrollToMiddle() {
              const container = $refs.container;
              const middle = (container.scrollWidth - container.clientWidth) / 2;
              container.scrollTo({ left: middle, behavior: 'smooth' });
            }
          }"
          x-init="scrollToMiddle()"
          x-ref="container"
        >
          <.testimonial_card :for={testimonial <- @testimonials} {testimonial} />
        </div>
      </div>
    </section>
    """
  end

  attr :content, :string, required: true
  attr :image_src, :string, required: true
  attr :rating, :integer, default: 5
  attr :name, :string, required: true
  attr :title, :string, required: true

  def testimonial_card(assigns) do
    ~H"""
    <article class={[
      "px-6 py-8 grow bg-slate-50 rounded-xl flex flex-col justify-between",
      "min-w-[500px] xl:min-w-[600px] min-h-[300px] lg:min-h-[400px] grow"
    ]}>
      <div class="flex flex-col gap-6">
        <div class="justify-start items-center inline-flex">
          <.icon
            :for={i <- 1..5}
            name="remix-star-fill"
            class={["w-5 h-5", if(i <= @rating, do: "text-[#FBBF10]", else: "text-slate-500")]}
          />
        </div>
        <p class="self-stretch text-slate-900 text-lg line-clamp-4">{@content}</p>
      </div>
      <div class="flex items-center gap-2">
        <div class="inline-flex shrink-0 rounded-full">
          <img
            class="w-10 h-10 rounded-full"
            src={@image_src}
            alt={@name <> ": " <> @title }
            title={@name}
            loading="lazy"
          />
        </div>
        <div class="flex flex-col items-start gap-1">
          <div class="text-slate-900 text-sm font-semibold leading-tight">
            {@name}
          </div>
          <div class="text-slate-600 text-sm font-normal leading-tight">
            {@title}
          </div>
        </div>
      </div>
    </article>
    """
  end

  attr :badge, :string, default: nil
  attr :icon, :string, default: nil
  attr :icon_class, :string, default: nil
  attr :color_primary, :string, default: "bg-primary-300"
  attr :color_secondary, :string, default: "bg-primary-100"
  attr :content, :string, required: true
  attr :to, :string, required: true
  attr :class, :string, default: nil, doc: "the class to add to this element"

  def promo_banner(assigns) do
    ~H"""
    <.a
      to={@to}
      class={[
        "flex items-center text-slate-900 text-xs font-semibold rounded-full p-1 select-none",
        @class,
        @color_secondary
      ]}
      title={@content}
    >
      <div class={["px-2 py-1 rounded-full flex items-center justify-center", @color_primary]}>
        <.icon :if={@icon} name={@icon} class={@icon_class} />
        <%= if @badge do %>
          {@badge}
        <% end %>
      </div>
      <div class="px-2 flex items-center gap-2.5">
        {@content}
        <.icon name="remix-arrow-right-line" class="w-3 h-3" />
      </div>
    </.a>
    """
  end

  attr :to, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :reverse, :boolean, default: false
  attr :image_path, :string, required: true
  attr :image_class, :string, default: nil
  attr :lazy_load, :boolean, default: true
  attr :link_type, :string, default: "a"
  attr :class, :any, default: nil

  def feature_card(assigns) do
    ~H"""
    <.a to={@to} title={@title} class={@class} link_type={@link_type}>
      <article class={[
        "h-[380px] 2xl:h-[400px] w-full p-8 bg-slate-50 rounded-3xl shadow-sm border border-slate-200 justify-between inline-flex overflow-hidden",
        "select-none transition duration-150 ease-in-out hover:shadow-2 focus:shadow-3 focus:bg-slate-100 active:bg-slate-100 active:shadow-3",
        if(@reverse, do: "flex-col-reverse", else: "flex-col")
      ]}>
        <div class={[if(not @reverse, do: "mb-8"), "flex flex-col gap-2.5"]}>
          <h3 class="text-slate-900 text-lg font-semibold">{@title}</h3>
          <h4 class="text-slate-600 text-sm font-normal leading-tight">{@description}</h4>
        </div>
        <img
          class={@image_class}
          src={static_url(PasswordlessWeb.Endpoint, @image_path)}
          alt={@title <> ": " <> @description}
          title={@title}
          loading={if @lazy_load, do: "lazy", else: "eager"}
        />
      </article>
    </.a>
    """
  end

  attr :badge, :string, default: nil
  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil

  def cta_header(assigns) do
    ~H"""
    <div class={["flex flex-col", @class]}>
      <badge class="text-primary-300 text-xs font-semibold uppercase mb-2">{@badge}</badge>
      <h2 class="text-white text-3xl md:text-5xl font-semibold font-display mb-4 md:leading-[60px]">
        {@title}
      </h2>
      <p class="text-white/60 text-xl font-normal leading-[30px]">
        {@subtitle}
      </p>
    </div>
    """
  end

  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]

  def code_cta(assigns) do
    ~H"""
    <section class="bg-slate-900 pb-8 md:pb-10">
      <.container max_width={@max_width}>
        <div class="grid lg:grid-cols-2 lg:gap-[124px]">
          <div class="items-center justify-center hidden lg:flex">
            <div class="flex items-center justify-center rounded-3xl p-4 bg-slate-950 relative">
              <div
                id="demo-editor"
                phx-hook="DemoEditorHook"
                class="w-[300px] lg:w-[500px] 2xl:w-[560px]"
              >
              </div>
              <div class="absolute bottom-7 right-7 flex items-center gap-2 bg-slate-950 p-2 rounded-lg">
                <.icon :for={l <- [:js, :ts]} name={"remix-#{l}"} class="w-6 h-6 rounded-sm" />
              </div>
            </div>
          </div>

          <div class="flex flex-col gap-16 lg:gap-[124px] py-10 lg:py-[124px]">
            <.cta_header
              badge={gettext("Try Demo")}
              title={gettext("Power of Playwright, managed in the cloud")}
              subtitle={
                gettext(
                  "No setup. No maintenance. No EC2 instances. Run your Playwright tests every minute from 10+ locations, at a fraction of the price of legacy providers."
                )
              }
            />
            <div class="flex items-center">
              <.button size="lg" title={gettext("Run")} to={~p"/auth/sign-up"} link_type="a" with_icon>
                <.icon name="custom-run" class="w-6 h-6 text-white" />
                {gettext("Run Demo")}
              </.button>
            </div>
          </div>
        </div>
      </.container>
    </section>
    """
  end

  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]
  attr :lazy_load, :boolean, default: true

  def benefits_cta(assigns) do
    ~H"""
    <section class="bg-slate-900 pb-10 overflow-hidden">
      <.container max_width={@max_width}>
        <div class="grid grid-cols-1 lg:grid-cols-2 lg:gap-[124px]">
          <div class="flex flex-col py-10 lg:py-[124px]">
            <.cta_header
              badge={gettext("Try Now")}
              title={gettext("Start boosting your release quality today")}
              subtitle={
                gettext(
                  "Try our free plan and book a one-to-one session with our engineers to create your first Passwordless. No credit card required."
                )
              }
              class="mb-12"
            />
            <.cta_list
              items={[
                "Create your first Passwordless",
                "Get a free 1:1 session with our engineers",
                "No credit card required"
              ]}
              class="mb-16 lg:mb-[124px]"
            />
            <div>
              <.button
                size="lg"
                title={gettext("Create Account")}
                to={~p"/auth/sign-up"}
                link_type="a"
              />
            </div>
          </div>

          <div class="hidden flex flex-col justify-center lg:flex overflow-visible">
            <div class="rounded-3xl p-4 bg-slate-950 z-10 lg:w-[902px]">
              <img
                src={static_url(PasswordlessWeb.Endpoint, ~p"/images/landing_page/hero.webp")}
                alt={Passwordless.config(:app_name)}
                title={Passwordless.config(:app_name)}
                class="rounded-xl z-10 lg:h-[620px] lg:w-[870px]"
                loading={if @lazy_load, do: "lazy", else: "eager"}
              />
            </div>
          </div>
        </div>
      </.container>
    </section>
    """
  end

  attr :items, :list, default: []
  attr :class, :any, default: nil

  def cta_list(assigns) do
    ~H"""
    <div class={["flex flex-col gap-4", @class]} role="list">
      <div :for={item <- @items} class="items-center gap-[9px] inline-flex" role="listitem">
        <div class="flex w-6 h-6 p-[3px] bg-primary-300 rounded-full justify-center items-center">
          <.icon name="remix-check-line" class="w-[18px] h-[18px] text-slate-900" />
        </div>
        <p class="text-[#F0FBC8] font-semibold">
          {item}
        </p>
      </div>
    </div>
    """
  end

  attr :items, :list, default: []
  attr :class, :any, default: nil

  def article_list(assigns) do
    ~H"""
    <div class={["flex flex-col gap-3", @class]} role="list">
      <div :for={item <- @items} class="flex items-center gap-4" role="listitem">
        <.icon name="custom-check-fancy" class="w-8 h-8 text-primary-500" />
        <p class="text-slate-900 font-semibold font-display">
          {item}
        </p>
      </div>
    </div>
    """
  end

  attr :max_width, :string, default: "xl", values: ["sm", "md", "lg", "xl", "full"]

  def pricing_cta(assigns) do
    ~H"""
    <section class="bg-slate-100 pb-10" {pricing_js_data()}>
      <.container max_width={@max_width}>
        <div class="flex flex-col py-10 md:py-[124px] gap-12">
          <.area_header badge={gettext("Pricing")} title={gettext("Simple, transparent pricing")} />

          <div class="flex flex-col items-center justify-center gap-4">
            <.pricing_tabs variable="chosenPricing" options={PasswordlessWeb.Product.pricing_modes()} />
          </div>

          <.pricing_plans />
        </div>
      </.container>
      <.pricing_details
        class="mx-6 lg:mx-10"
        plans={PasswordlessWeb.Product.pricing_plans()}
        sections={PasswordlessWeb.Product.pricing_plan_features()}
      />
    </section>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :class, :any, default: nil
  slot :inner_block

  def contact_card(assigns) do
    ~H"""
    <article>
      <div class="flex flex-col gap-2.5">
        <h3 class="text-slate-900 text-lg font-semibold">{@title}</h3>
        <h4 class="text-slate-600 text-sm font-normal leading-tight">{@description}</h4>
      </div>
      <div>
        {render_slot(@inner_block)}
      </div>
    </article>
    """
  end

  attr :title, :string, required: true

  def hero_placeholder(assigns) do
    ~H"""
    <div class="flex flex-col items-center px-4 md:px-16 lg:px-0 relative bg-slate-900 py-8 h-[300px] overflow-hidden rounded-xl">
      <h4 class="text-white text-xl font-semibold font-display mb-4">{@title}</h4>
      <img
        src={static_url(PasswordlessWeb.Endpoint, ~p"/images/landing_page/chart-line.svg")}
        alt={Passwordless.config(:app_name)}
        title={Passwordless.config(:app_name)}
        class="absolute left-0 bottom-0 z-0 object-fill w-full"
      />
      <div class="rounded-3xl p-4 bg-slate-950 max-w-[500px] relative z-1">
        <img
          src={static_url(PasswordlessWeb.Endpoint, ~p"/images/landing_page/hero.webp")}
          alt={gettext("Uptime Monitoring Service Made For Developers")}
          title={Passwordless.config(:app_name)}
          class="rounded-xl"
          fetchpriority="high"
        />
      </div>
    </div>
    """
  end
end
