defmodule PasswordlessWeb.Translator do
  @moduledoc """
  Translates actions to human-readable strings.
  """

  defmacro build_action_translations() do
    actions =
      "../../priv/translator/actions.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()

    translators =
      for {key, value} <- actions do
        quote do
          def translate_action(unquote(:"#{key}")), do: unquote(Macro.escape(value))
        end
      end

    translators ++
      [
        quote do
          def translate_action(action) do
            Phoenix.Naming.humanize(action)
          end
        end
      ]
  end
end
