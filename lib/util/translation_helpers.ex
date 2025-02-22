defmodule Util.TranslationHelpers do
  @moduledoc """
  You can override the default messages by defining a module that implements the translate/1 function.
  For example,:

      # /lib/<your_app>_web/petal_framework_translations.ex

      defmodule YourAppWeb.PetalFrameworkTranslations do
        import YourAppWeb.Gettext

        # You can omit any of the following functions if you don't want to override the default message.
        def translate("Showing"), do: gettext("Showing")
        def translate("to"), do: gettext("to")
        def translate("of"), do: gettext("of")
        def translate("rows"), do: gettext("rows")
        def translate("Equals"), do: gettext("Equals")
        def translate("Not equal"), do: gettext("Not equal")
        def translate("Search (case insensitive)"), do: gettext("Search (case insensitive)")
        def translate("Is empty"), do: gettext("Is empty")
        def translate("Not empty"), do: gettext("Not empty")
        def translate("Less than or equals"), do: gettext("Less than or equals")
        def translate("Less than"), do: gettext("Less than")
        def translate("Greater than or equals"), do: gettext("Greater than or equals")
        def translate("Greater than"), do: gettext("Greater than")
        def translate("Search in"), do: gettext("Search in")
        def translate("Contains"), do: gettext("Contains")
        def translate("Search (case sensitive)"), do: gettext("Search (case sensitive)")
        def translate("Search (case sensitive) (and)"), do: gettext("Search (case sensitive) (and)")
        def translate("Search (case sensitive) (or)"), do: gettext("Search (case sensitive) (or)")
        def translate("Search (case insensitive) (and)"), do: gettext("Search (case insensitive) (and)")
        def translate("Search (case insensitive) (or)"), do: gettext("Search (case insensitive) (or)")
      end

  Then in your `config/config.exs` file:

      config :passwordless, :translation_helper_module, YourAppWeb.PetalFrameworkTranslations

  """

  @doc """
  For use in Petal Framework components. eg in a HEEX template:

        <div><%= Util.TranslationHelpers.translate("something to translate") %></div>
  """
  def translate(key) do
    case Application.fetch_env(:passwordless, :translation_helper_module) do
      {:ok, mod} ->
        try do
          if function_exported?(mod, :text, 1) do
            IO.puts("""
            Petal Framework translations warning - the function `text/1` has been deprecated. Please rename the functions in your translation_helper_module from `text/1` to `translate/1`:

            eg, change:
                defmodule PasswordlessWeb.PetalFrameworkTranslations do
                  import PasswordlessWeb.Gettext

                  def text("Showing"), do: gettext("Showing")
                  def text("to"), do: gettext("to")
                  ...
                end

            to:

                defmodule PasswordlessWeb.PetalFrameworkTranslations do
                  import PasswordlessWeb.Gettext

                  def translate("Showing"), do: gettext("Showing")
                  def translate("to"), do: gettext("to")
                  ...
                end
            """)

            mod.text(key)
          else
            mod.translate(key)
          end
        rescue
          _ in FunctionClauseError ->
            key
        end

      _ ->
        key
    end
  end

  @doc """
  Used to translate errors from an Ecto.Changeset. eg in a component displaying errors:

        # field == %Phoenix.HTML.FormField{}
        Enum.map(field.errors, &Util.TranslationHelpers.translate_error(&1))
  """
  def translate_error({msg, opts}) do
    config_translator = get_error_translator_from_config()

    if config_translator do
      config_translator.({msg, opts})
    else
      fallback_translate_error(msg, opts)
    end
  end

  defp fallback_translate_error(msg, opts) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      try do
        String.replace(acc, "%{#{key}}", to_string(value))
      rescue
        e ->
          IO.warn(
            """
            the fallback message translator for the form_field_error function cannot handle the given value.

            Hint: you can set up the `error_translator_function` to route all errors to your application helpers:

            Given value: #{inspect(value)}

            Exception: #{Exception.message(e)}
            """,
            __STACKTRACE__
          )

          "invalid value"
      end
    end)
  end

  defp get_error_translator_from_config do
    case Application.get_env(:passwordless, :error_translator_function) do
      {module, function} -> &apply(module, function, [&1])
      nil -> nil
    end
  end
end
