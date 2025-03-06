defmodule Passwordless.MJML.HTMLScrubber do
  @moduledoc false
  alias HtmlSanitizeEx.Scrubber.Meta

  require HtmlSanitizeEx.Scrubber.Meta

  Meta.remove_cdata_sections_before_scrub()
  Meta.strip_comments()

  Meta.allow_tag_with_these_attributes("p", [])
  Meta.allow_tag_with_these_attributes("h1", [])
  Meta.allow_tag_with_uri_attributes("a", ["href"], ["https", "mailto"])

  Meta.strip_everything_not_covered()
end
