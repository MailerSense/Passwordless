defmodule Passwordless.SMS do
  @moduledoc """
  Provides functionality for sending SMS messages via AWS SNS.
  This module is primarily used for sending OTP codes for authentication.
  """

  require Logger

  @languages ~w(en de fr)a

  @otp_templates %{
    en: "Your verification code for <%= app_name %> is: <%= code %>",
    de: "Ihr Verifizierungscode für <%= app_name %> lautet: <%= code %>",
    fr: "Votre code de vérification pour <%= app_name %> est: <%= code %>"
  }

  @doc """
  Sends an SMS message to the specified phone number using AWS SNS.

  ## Parameters
    * `phone_number` - The recipient's phone number in E.164 format (e.g., "+12065550100")
    * `message` - The text message to send
    * `opts` - Optional parameters:
      * `:sender_id` - The sender ID to display (if supported by the recipient's carrier)
      * `:max_price` - The maximum price in USD that you are willing to spend to send the SMS message
      * `:message_type` - Either "Promotional" or "Transactional" (default: "Transactional")

  ## Returns
    * `{:ok, message_id}` - If the message was sent successfully
    * `{:error, reason}` - If there was an error sending the message
  """
  @spec send_sms(String.t(), String.t(), Keyword.t()) :: {:ok, String.t()} | {:error, any()}
  def send_sms(phone_number, message, opts \\ []) do
    client = AWS.Session.get_client!()

    # Build the request parameters
    params = build_params(phone_number, message, opts)

    # Send the message using AWS SNS
    params = Map.put(params, :message, message)

    case AWS.SNS.send_raw_sms(client, params) do
      {:ok, %{body: %{message_id: message_id}}} ->
        Logger.info("SMS sent successfully to #{phone_number}, message_id: #{message_id}")
        {:ok, message_id}

      {:error, error} ->
        Logger.error("Failed to send SMS to #{phone_number}: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Sends an OTP code to the specified phone number.

  ## Parameters
    * `phone_number` - The recipient's phone number in E.164 format
    * `otp_code` - The OTP code to send
    * `app_name` - The name of the application (used in the message)
    * `opts` - Additional options to pass to `send_sms/3`:
      * `:language` - The language to use for the message (default: :en)

  ## Returns
    * `{:ok, message_id}` - If the message was sent successfully
    * `{:error, reason}` - If there was an error sending the message
  """
  @spec send_otp(String.t(), String.t(), String.t(), Keyword.t()) :: {:ok, String.t()} | {:error, any()}
  def send_otp(phone_number, otp_code, app_name, opts \\ []) do
    language = Keyword.get(opts, :language, :en)

    # Ensure the language is supported, default to English if not
    language = if language in @languages, do: language, else: :en

    # Get the template for the selected language
    template = Map.get(@otp_templates, language)

    # Format the message with EEx
    message = EEx.eval_string(template, app_name: app_name, code: otp_code)

    # Always set message type to Transactional for OTP codes
    opts = Keyword.put_new(opts, :message_type, "Transactional")

    send_sms(phone_number, message, opts)
  end

  @doc """
  Returns a list of supported languages for SMS templates.
  """
  def supported_languages, do: @languages

  @doc """
  Returns the OTP template for the specified language.
  If the language is not supported, returns the English template.
  """
  def get_otp_template(language) when language in @languages do
    Map.get(@otp_templates, language)
  end

  def get_otp_template(_language), do: Map.get(@otp_templates, :en)

  @doc """
  Formats an OTP message using the template for the specified language.
  """
  def format_otp_message(language, app_name, otp_code) do
    template = get_otp_template(language)
    EEx.eval_string(template, app_name: app_name, code: otp_code)
  end

  # Private functions

  defp build_params(phone_number, _message, opts) do
    # Start with the required parameters
    params = %{
      phone_number: phone_number
    }

    # Add optional parameters if provided
    params =
      if sender_id = Keyword.get(opts, :sender_id),
        do: Map.put(params, :sender_id, sender_id),
        else: params

    params =
      if max_price = Keyword.get(opts, :max_price),
        do: Map.put(params, :max_price, to_string(max_price)),
        else: params

    # Default to Transactional for OTP codes
    message_type = Keyword.get(opts, :message_type, "Transactional")

    Map.put(params, :message_attributes, %{
      "AWS.SNS.SMS.SMSType" => %{
        data_type: "String",
        string_value: message_type
      }
    })
  end
end
