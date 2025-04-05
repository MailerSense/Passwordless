defmodule Passwordless.SMS do
  @moduledoc """
  Provides functionality for sending SMS messages via AWS SNS.
  This module is primarily used for sending OTP codes for authentication.
  """

  require Logger

  @templates [
    en: "Your verification code for <%= app_name %> is: <%= code %>. To stop receiving these messages, visit <%= url %>.",
    de:
      "Ihr Verifizierungscode für <%= app_name %> lautet: <%= code %>. To stop receiving these messages, visit <%= url %>.",
    fr:
      "Votre code de vérification pour <%= app_name %> est: <%= code %>. To stop receiving these messages, visit <%= url %>."
  ]
  @languages Keyword.keys(@templates)

  @doc """
  Formats the message to be sent via SMS.
  """
  def format_message!(language, bindings \\ []) when language in @languages do
    @templates
    |> Keyword.fetch!(language)
    |> EEx.eval_string(bindings)
  end
end
