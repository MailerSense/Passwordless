defmodule Passwordless.Locale do
  @moduledoc """
  Provides localization support for the application.
  """

  use Cldr,
    default_locale: "en",
    locales: [
      "en"
    ],
    gettext: Passwordless.Gettext,
    data_dir: Path.join(:code.priv_dir(:passwordless), "cldr"),
    providers: [Cldr.Number],
    precompile_number_formats: ["¤¤#,##0.##"],
    precompile_transliterations: [{:latn, :arab}, {:thai, :latn}],
    json_library: Jason

  @countries Application.compile_env!(:passwordless, :countries)
  @country_codes Keyword.keys(@countries)

  @languages Application.compile_env!(:passwordless, :languages)
  @language_codes Keyword.keys(@languages)

  def countries, do: @countries
  def country_codes, do: @country_codes

  def languages, do: @languages
  def language_codes, do: @language_codes
end
