defmodule PasswordlessWeb.SEO do
  @moduledoc false
  use PasswordlessWeb, :verified_routes

  use SEO,
    json_library: Jason,
    site: &__MODULE__.site_config/1,
    open_graph: &__MODULE__.open_graph_config/1,
    twitter: &__MODULE__.twitter_config/1,
    breadcrumb: &__MODULE__.breadcrumb_config/1

  def site_config(conn) do
    SEO.Site.build(
      title: get_in(conn.assigns, [Access.key(:page_title, Passwordless.config(:app_name))]),
      default_title: Passwordless.config(:app_name),
      description: get_in(conn.assigns, [Access.key(:page_description, Passwordless.config(:seo_description))]),
      theme_color: "#243837",
      windows_tile_color: "#243837",
      mask_icon_color: "#243837",
      manifest_url: "/site.webmanifest"
    )
  end

  def open_graph_config(conn) do
    SEO.OpenGraph.build(
      title: get_in(conn.assigns, [Access.key(:page_title, Passwordless.config(:app_name))]),
      image: %SEO.OpenGraph.Image{
        url: "https://cdn.passwordless.tools/public-sharing/twitter-card.webp",
        alt: "Passwordless Promo Banner",
        type: "image/webp",
        width: 1536,
        height: 768
      },
      description: get_in(conn.assigns, [Access.key(:page_description, Passwordless.config(:seo_description))]),
      site_name: Passwordless.config(:app_name),
      locale: "en_US"
    )
  end

  def twitter_config(conn) do
    SEO.Twitter.build(
      title: get_in(conn.assigns, [Access.key(:page_title, Passwordless.config(:app_name))]),
      description: get_in(conn.assigns, [Access.key(:page_description, Passwordless.config(:seo_description))]),
      creator: "@PasswordlessIO",
      image: "https://cdn.passwordless.tools/public-sharing/twitter-card.webp",
      image_alt: "Easy, Continuous Monitoring With Playwright",
      card: :summary_large_image
    )
  end

  def breadcrumb_config(conn) do
    SEO.Breadcrumb.List.build([
      %{
        name: get_in(conn.assigns, [Access.key(:page_title, Passwordless.config(:app_name))]),
        item: PasswordlessWeb.Layouts.canonical_url(conn)
      }
    ])
  end
end
