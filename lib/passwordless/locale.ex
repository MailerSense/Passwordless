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

  @languages Application.compile_env!(:passwordless, :languages)
  @language_keys Keyword.keys(@languages)

  def languages, do: @languages
  def language_keys, do: @language_keys
end
