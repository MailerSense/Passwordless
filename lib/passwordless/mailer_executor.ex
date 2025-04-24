defmodule Passwordless.MailerExecutor do
  @moduledoc """
  This module is responsible for delivering emails using the Mailer module.
  """

  use Oban.Pro.Worker, queue: :mailer, max_attempts: 5, tags: ["mailer", "executor"]

  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.EmailMessage
  alias Passwordless.Mailer
  alias Swoosh.Email, as: SwooshEmail

  require Logger

  @impl true
  def process(%Oban.Job{args: %{"app_id" => app_id, "domain_id" => domain_id, "email_message_id" => email_message_id}})
      when is_binary(app_id) and is_binary(email_message_id) do
    with %App{state: :active} = app <- Passwordless.get_app(app_id),
         %Domain{verified: true, purpose: :email} = domain <- Passwordless.get_domain(domain_id),
         %EmailMessage{
           sender: sender,
           sender_name: sender_name,
           recipient: recipient,
           recipient_name: recipient_name,
           reply_to: reply_to,
           reply_to_name: reply_to_name,
           subject: subject,
           html_content: html_content,
           text_content: text_content
         } = message <- Passwordless.get_email_message(app, email_message_id) do
      email =
        SwooshEmail.new()
        |> SwooshEmail.from({sender_name, sender})
        |> SwooshEmail.to({recipient_name, recipient})
        |> SwooshEmail.reply_to({reply_to_name, reply_to})
        |> SwooshEmail.subject(subject)
        |> SwooshEmail.html_body(html_content)
        |> SwooshEmail.text_body(text_content)

      email =
        case message do
          %EmailMessage{metadata: %EmailMessage.Metadata{headers: headers}} when is_list(headers) ->
            Enum.reduce(headers, email, fn %EmailMessage.Metadata.Header{name: name, value: value}, acc ->
              SwooshEmail.header(acc, name, value)
            end)

          _ ->
            email
        end

      Logger.info("Sending email: #{inspect(email)}")

      result =
        with {:ok, external_id} <- Mailer.deliver_via_domain(email, domain),
             {:ok, _mapping} <- Passwordless.record_email_message_mapping(app, message, external_id),
             do: :ok

      Logger.info("Email delivered successfully: #{inspect(result)}")

      result
    else
      value ->
        Logger.error("Failed to deliver email: #{inspect(value)}")
        {:error, value}
    end
  end

  @impl true
  def process(%Oban.Job{args: %{"email" => email, "domain_id" => domain_id}})
      when is_map(email) and is_binary(domain_id) do
    with {:ok, domain} <- Passwordless.fetch_domain(domain_id),
         {:ok, _metadata} <-
           email
           |> Mailer.from_map()
           |> Mailer.deliver_via_domain(domain),
         do: :ok
  end

  @impl true
  def process(%Oban.Job{args: %{"email" => email}}) when is_map(email) do
    with {:ok, _metadata} <- Mailer.deliver(Mailer.from_map(email)), do: :ok
  end
end
