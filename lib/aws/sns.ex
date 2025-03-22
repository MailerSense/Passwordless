defmodule AWS.SNS do
  @moduledoc """
  Provides AWS SNS (Simple Notification Service) functionality.
  This module is used for sending SMS messages via AWS SNS.
  """

  @doc """
  Sends a raw SMS message via AWS SNS.

  ## Parameters
    * `client` - The AWS client to use for the request
    * `params` - The parameters for the SNS publish request, including:
      * `:phone_number` - The recipient's phone number in E.164 format
      * `:message` - The text message to send
      * `:sender_id` - (optional) The sender ID to display
      * `:max_price` - (optional) The maximum price in USD
      * `:message_attributes` - (optional) Additional message attributes

  ## Returns
    * `{:ok, %{body: %{message_id: message_id}}}` - If the message was sent successfully
    * `{:error, reason}` - If there was an error sending the message
  """
  @spec send_raw_sms(AWS.Client.t(), map()) :: {:ok, map()} | {:error, any()}
  def send_raw_sms(client, params) do
    params.message
    |> ExAws.SNS.publish(Map.delete(params, :message))
    |> ExAws.request(client)
  end
end
