defmodule PasswordlessWeb.SchemaMarkup do
  @moduledoc """
  Helper functions for generating SEO microdata.
  """

  use Phoenix.Component

  attr :url, :string, required: true, doc: "page url"
  attr :site_name, :string, required: true, doc: "site name"

  def site(assigns) do
    assigns =
      assign(assigns, :item, %{
        "@context": "https://schema.org/",
        "@type": "WebSite",
        name: assigns[:site_name],
        url: assigns[:url]
      })

    ~H"""
    <script type="application/ld+json">
      <%= Phoenix.HTML.raw(Jason.encode!(@item)) %>
    </script>
    """
  end

  attr :associated_headline, :string, required: true, doc: "site name"
  attr :associated_abstract, :string, required: true, doc: "site name"
  attr :associated_related_link, :string, required: true, doc: "site name"
  attr :associated_significant_links, :list, required: true, doc: "site name"
  attr :associated_keywords, :list, required: true, doc: "site name"

  def page(assigns) do
    assigns =
      assign(assigns, :item, %{
        "@context": "https://schema.org",
        "@type": "WebPage",
        headline: assigns[:associated_headline],
        abstract: assigns[:associated_abstract],
        relatedLink: assigns[:associated_related_link],
        significantLink: assigns[:associated_significant_links],
        keywords: assigns[:associated_keywords]
      })

    ~H"""
    <script type="application/ld+json">
      <%= Phoenix.HTML.raw(Jason.encode!(@item)) %>
    </script>
    """
  end

  attr :url, :string, required: true, doc: "page url"
  attr :name, :string, default: nil, doc: "page headline"
  attr :image, :string, default: nil, doc: "page headline"
  attr :logo, :string, default: nil, doc: "page headline"
  attr :legal_name, :string, required: true, doc: "site name"
  attr :description, :string, required: true, doc: "site name"
  attr :same_as, :list, required: true, doc: "site name"
  attr :contact_type, :string, required: true, doc: "site name"
  attr :contact_email, :string, required: true, doc: "site name"

  def organization(assigns) do
    assigns =
      assign(assigns, :item, %{
        "@context": "https://schema.org",
        "@type": "Organization",
        url: assigns[:url],
        name: assigns[:name],
        image: assigns[:image],
        logo: assigns[:logo],
        description: assigns[:description],
        legalName: assigns[:legal_name],
        sameAs: assigns[:same_as],
        contactPoint: [
          %{
            "@type": "ContactPoint",
            contactType: assigns[:contact_type],
            email: assigns[:contact_email]
          }
        ]
      })

    ~H"""
    <script type="application/ld+json">
      <%= Phoenix.HTML.raw(Jason.encode!(@item)) %>
    </script>
    """
  end

  attr :items, :list, default: [], doc: "site name"

  def breadcrumb_list(assigns) do
    assigns =
      assign(assigns, :item, %{
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        itemListElement:
          Enum.map(assigns[:items], fn %{id: id, name: name, position: position} ->
            %{
              "@type": "ListItem",
              position: position,
              item: %{
                "@id": id,
                name: name
              }
            }
          end)
      })

    ~H"""
    <script type="application/ld+json">
      <%= Phoenix.HTML.raw(Jason.encode!(@item)) %>
    </script>
    """
  end
end
