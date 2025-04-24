defmodule Passwordless.Email.Adapter.SESParser do
  @moduledoc """
  Parses an event from Amazon SQS/SNS into email logs.
  """

  @kinds [
    "Bounce",
    "Complaint",
    "Delivery",
    "Send",
    "Reject",
    "Open",
    "Click",
    "DeliveryDelay",
    "Rendering Failure",
    "Subscription"
  ]
  @objects %{
    "Bounce" => "bounce",
    "Complaint" => "complaint",
    "Delivery" => "delivery",
    "Send" => "send",
    "Reject" => "reject",
    "Open" => "open",
    "Click" => "click",
    "DeliveryDelay" => "deliveryDelay",
    "Rendering Failure" => "failure",
    "Subscription" => "subscription"
  }
  @bounce_types %{
    "Permanent" => "permanent",
    "Transient" => "transient",
    "Undetermined" => "undetermined"
  }
  @bounce_subtypes %{
    "General" => "general",
    "NoEmail" => "no_email",
    "Suppressed" => "suppressed",
    "OnAccountSuppressionList" => "on_account_suppression_list",
    "Undetermined" => "undetermined",
    "MailboxFull" => "mailbox_full",
    "MessageTooLarge" => "message_too_large",
    "ContentRejected" => "content_rejected",
    "AttachmentRejected" => "attachment_rejected"
  }
  @complaint_types %{
    "abuse" => "abuse",
    "auth-failure" => "auth_failure",
    "fraud" => "fraud",
    "not-spam" => "not_spam",
    "other" => "other",
    "virus" => "virus"
  }
  @complaint_subtypes %{
    "OnAccountSuppressionList" => "on_account_suppression_list"
  }
  @delay_types %{
    "InternalFailure" => "internal_failure",
    "General" => "general",
    "MailboxFull" => "mailbox_full",
    "SpamDetected" => "spam_detected",
    "RecipientServerError" => "recipient_server_error",
    "IPFailure" => "ip_failure",
    "TransientCommunicationFailure" => "transient_communication_failure",
    "BYOIPHostNameLookupUnavailable" => "byoip_host_name_lookup_unavailable",
    "Undetermined" => "undetermined",
    "SendingDeferral" => "sending_deferral"
  }

  def parse(payload) when is_map(payload) do
    kind =
      case {payload["notificationType"], payload["eventType"]} do
        {k, _} when is_binary(k) and k in @kinds -> {:ok, k}
        {_, k} when is_binary(k) and k in @kinds -> {:ok, k}
        {_, _} -> {:error, :invalid_kind}
      end

    with {:ok, kind} <- kind,
         {:ok, object_name} <- Map.fetch(@objects, kind),
         {:ok, message} <- parse_mail(payload["mail"]),
         {:ok, message_details, event_details} <- parse_object(kind, payload[object_name]),
         :ok <- message_valid?(message),
         do: {:ok, Map.merge(message, message_details), event_details}
  end

  def parse(_), do: {:error, :invalid_message_payload}

  # Private
  defp parse_object("Bounce", %{"bouncedRecipients" => bounced_recipients, "timestamp" => timestamp} = payload)
       when is_list(bounced_recipients) and is_binary(timestamp) do
    timestamp =
      case Timex.parse(String.replace(timestamp, " ", ""), "{ISO:Extended}") do
        {:ok, %DateTime{} = ts} -> ts
        _ -> DateTime.utc_now()
      end

    feedback_id =
      case payload["feedbackId"] do
        id when is_binary(id) -> id
        _ -> nil
      end

    bounce_type =
      case payload["bounceType"] do
        type when is_binary(type) -> Map.get(@bounce_types, type, "unknown")
        _ -> nil
      end

    bounce_subtype =
      case payload["bounceSubType"] do
        subtype when is_binary(subtype) -> Map.get(@bounce_subtypes, subtype, "unknown")
        _ -> nil
      end

    recipients =
      Enum.map(bounced_recipients, fn
        %{"emailAddress" => email_address} = recipient ->
          {name, email} = parse_full_email(email_address)

          %{
            name: name,
            email: email,
            action: recipient["action"],
            status: recipient["status"],
            diagnostic_code: recipient["diagnosticCode"]
          }
      end)

    {:ok, %{state: :bounced},
     %{
       kind: :bounce,
       feedback_id: feedback_id,
       bounce_type: bounce_type,
       bounce_subtype: bounce_subtype,
       bounced_recipients: recipients,
       happened_at: timestamp
     }}
  end

  defp parse_object("Complaint", %{"complainedRecipients" => complained_recipients, "timestamp" => timestamp} = payload)
       when is_list(complained_recipients) and is_binary(timestamp) do
    timestamp =
      case Timex.parse(String.replace(timestamp, " ", ""), "{ISO:Extended}") do
        {:ok, %DateTime{} = ts} -> ts
        _ -> DateTime.utc_now()
      end

    feedback_id =
      case payload["feedbackId"] do
        id when is_binary(id) -> id
        _ -> nil
      end

    user_agent =
      case payload["userAgent"] do
        ua when is_binary(ua) -> ua
        _ -> nil
      end

    complaint_type =
      case payload["complaintFeedbackType"] do
        feedback when is_binary(feedback) -> Map.get(@complaint_types, feedback, "unknown")
        _ -> nil
      end

    complaint_subtype =
      case payload["complaintSubType"] do
        subtype when is_binary(subtype) -> Map.get(@complaint_subtypes, subtype, "unknown")
        _ -> nil
      end

    recipients =
      Enum.map(complained_recipients, fn %{"emailAddress" => email_address} ->
        {name, email} = parse_full_email(email_address)
        %{name: name, email: email}
      end)

    {:ok, %{state: :complaint_received},
     %{
       kind: :complaint,
       feedback_id: feedback_id,
       complaint_type: complaint_type,
       complaint_subtype: complaint_subtype,
       complaint_user_agent: user_agent,
       bounced_recipients: recipients,
       happened_at: timestamp
     }}
  end

  defp parse_object("Delivery", %{"recipients" => recipients, "timestamp" => timestamp} = payload)
       when is_list(recipients) and is_binary(timestamp) do
    timestamp =
      case Timex.parse(String.replace(timestamp, " ", ""), "{ISO:Extended}") do
        {:ok, %DateTime{} = ts} -> ts
        _ -> DateTime.utc_now()
      end

    recipients =
      Enum.map(recipients, fn recipient ->
        {name, email} = parse_full_email(recipient)
        %{name: name, email: email}
      end)

    smtp_response =
      case payload["smtpResponse"] do
        smtp when is_binary(smtp) -> smtp
        _ -> nil
      end

    reporting_mta =
      case payload["reportingMTA"] do
        mta when is_binary(mta) -> mta
        _ -> nil
      end

    processing_time_millis =
      case payload["processingTimeMillis"] do
        ptm when is_integer(ptm) -> ptm
        _ -> nil
      end

    {:ok, %{state: :delivered},
     %{
       kind: :delivery,
       recipients: recipients,
       delivery_smtp_response: smtp_response,
       delivery_reporting_mta: reporting_mta,
       delivery_processing_time_millis: processing_time_millis,
       happened_at: timestamp
     }}
  end

  defp parse_object("Send", %{}), do: {:ok, %{state: :sent}, %{kind: :send, happened_at: DateTime.utc_now()}}

  defp parse_object("Reject", %{"reason" => reason}) when is_binary(reason),
    do: {:ok, %{state: :rejected}, %{kind: :reject, reject_reason: :bad_request, happened_at: DateTime.utc_now()}}

  defp parse_object("Open", %{"timestamp" => timestamp} = payload) when is_binary(timestamp) do
    timestamp =
      case Timex.parse(String.replace(timestamp, " ", ""), "{ISO:Extended}") do
        {:ok, %DateTime{} = ts} -> ts
        _ -> DateTime.utc_now()
      end

    user_agent =
      case payload["userAgent"] do
        ua when is_binary(ua) -> ua
        _ -> nil
      end

    ip_address =
      case payload["ipAddress"] do
        ip when is_binary(ip) -> ip
        _ -> nil
      end

    {:ok, %{state: :opened},
     %{
       kind: :open,
       open_user_agent: user_agent,
       open_ip_address: ip_address,
       happened_at: timestamp
     }}
  end

  defp parse_object("Click", %{"timestamp" => timestamp} = payload) when is_binary(timestamp) do
    timestamp =
      case Timex.parse(String.replace(timestamp, " ", ""), "{ISO:Extended}") do
        {:ok, %DateTime{} = ts} -> ts
        _ -> DateTime.utc_now()
      end

    user_agent =
      case payload["userAgent"] do
        ua when is_binary(ua) -> ua
        _ -> nil
      end

    ip_address =
      case payload["ipAddress"] do
        ip when is_binary(ip) -> ip
        _ -> nil
      end

    link =
      case payload["link"] do
        link when is_binary(link) -> link
        _ -> nil
      end

    link_tags =
      case payload["linkTags"] do
        tags when is_list(tags) -> tags
        _ -> nil
      end

    {:ok, %{state: :clicked},
     %{
       kind: :click,
       click_url: link,
       click_url_tags: link_tags,
       click_user_agent: user_agent,
       click_ip_address: ip_address,
       happened_at: timestamp
     }}
  end

  defp parse_object("DeliveryDelay", %{"delayedRecipients" => delayed_recipients, "timestamp" => timestamp} = payload) do
    timestamp =
      case Timex.parse(String.replace(timestamp, " ", ""), "{ISO:Extended}") do
        {:ok, %DateTime{} = ts} -> ts
        _ -> DateTime.utc_now()
      end

    expiration_time =
      with {:ok, expiration_time} <- Map.fetch(payload, "expirationTime"),
           {:ok, %DateTime{} = ts} <-
             Timex.parse(String.replace(expiration_time, " ", ""), "{ISO:Extended}") do
        ts
      else
        _ -> nil
      end

    reporting_mta =
      case payload["reportingMTA"] do
        mta when is_binary(mta) -> mta
        _ -> nil
      end

    delay_type =
      case payload["delayType"] do
        type when is_binary(type) -> Map.get(@delay_types, type, "unknown")
        _ -> nil
      end

    recipients =
      Enum.map(delayed_recipients, fn
        %{"emailAddress" => email_address} = recipient ->
          {name, email} = parse_full_email(email_address)

          %{
            name: name,
            email: email,
            status: recipient["status"],
            diagnostic_code: recipient["diagnosticCode"]
          }
      end)

    {:ok, %{state: :delayed},
     %{
       kind: :delay,
       delay_reason: delay_type,
       delay_reporting_mta: reporting_mta,
       delay_expiration_time: expiration_time,
       delayed_recipients: recipients,
       happened_at: timestamp
     }}
  end

  defp parse_object("Subscription", %{"timestamp" => timestamp} = payload) when is_map(payload) do
    timestamp =
      case Timex.parse(String.replace(timestamp, " ", ""), "{ISO:Extended}") do
        {:ok, %DateTime{} = ts} -> ts
        _ -> DateTime.utc_now()
      end

    contact_list =
      case payload["contactList"] do
        cl when is_binary(cl) -> cl
        _ -> nil
      end

    source =
      case payload["source"] do
        s when is_binary(s) -> s
        _ -> nil
      end

    {:ok, %{},
     %{
       kind: :subscription,
       source: source,
       contact_list: contact_list,
       happened_at: timestamp
     }}
  end

  defp parse_object("Rendering Failure", payload) when is_map(payload) do
    error_message =
      case payload["errorMessage"] do
        em when is_binary(em) -> em
        _ -> nil
      end

    teplate_name =
      case payload["templateName"] do
        tn when is_binary(tn) -> tn
        _ -> nil
      end

    {:ok, %{},
     %{
       kind: :rendering_failure,
       error_message: error_message,
       teplate_name: teplate_name,
       happened_at: DateTime.utc_now()
     }}
  end

  defp parse_object(_kind, _payload), do: {:error, :invalid_object_payload}

  defp parse_mail(%{"messageId" => message_id, "destination" => destination, "source" => source} = payload)
       when is_binary(message_id) and is_binary(source) do
    sending_account_id =
      case payload["sendingAccountId"] do
        sai when is_binary(sai) -> sai
        _ -> nil
      end

    source_ip =
      case payload["sourceIp"] do
        si when is_binary(si) -> si
        _ -> nil
      end

    source_arn =
      case payload["sourceArn"] do
        arn when is_binary(arn) -> arn
        _ -> nil
      end

    tags = parse_tags(Map.get(payload, "tags"))

    headers =
      case Map.get(payload, "headers") do
        h when is_list(h) -> h
        _ -> nil
      end

    headers_truncated =
      case Map.get(payload, "headersTruncated") do
        t when is_boolean(t) -> t
        _ -> false
      end

    parsed_message = %{
      external_id: message_id,
      metadata:
        %{
          tags: tags,
          source: source,
          source_ip: source_ip,
          source_arn: source_arn,
          sending_account_id: sending_account_id,
          headers: headers,
          headers_truncated: headers_truncated
        }
        |> Enum.filter(fn {_, v} -> Util.present?(v) end)
        |> Map.new()
    }

    parsed_message = Map.merge(parsed_message, parse_common_headers(payload["commonHeaders"]))

    {dest_name, dest_email} = parse_email_list(destination)
    {sender_name, sender_email} = parse_email_list(source)

    parsed_message =
      parsed_message
      |> Map.put_new(:sender, sender_email)
      |> Map.put_new(:sender_name, sender_name)
      |> Map.put_new(:recipient, dest_email)
      |> Map.put_new(:recipient_name, dest_name)
      |> Enum.filter(fn {_, v} -> Util.present?(v) end)
      |> Map.new()

    {:ok, parsed_message}
  end

  defp parse_mail(_), do: {:error, :invalid_mail_payload}

  defp parse_email_list([d]) when is_binary(d) do
    parse_full_email(d)
  end

  defp parse_email_list(d) when is_binary(d) do
    parse_full_email(d)
  end

  defp parse_email_list(_), do: {nil, nil}

  defp parse_common_headers(headers) when is_map(headers) do
    {from_name, from_email} =
      case Map.get(headers, "from") do
        [f] when is_binary(f) -> parse_full_email(f)
        from when is_binary(from) -> parse_full_email(from)
        _ -> {nil, nil}
      end

    {to_name, to_email} =
      case Map.get(headers, "to") do
        [t] when is_binary(t) -> parse_full_email(t)
        to when is_binary(to) -> parse_full_email(to)
        _ -> {nil, nil}
      end

    subject = Map.get(headers, "subject")

    %{
      sender: from_email,
      sender_name: from_name,
      recipient: to_email,
      recipient_name: to_name,
      subject: subject
    }
  end

  defp parse_common_headers(_), do: %{}

  defp parse_tags(tags) when is_map(tags) do
    tags
    |> Enum.map(fn
      {k, v} when is_binary(k) and is_list(v) -> {String.trim(k), Enum.map(v, &String.trim/1)}
      {k, v} when is_binary(k) and is_binary(v) -> {String.trim(k), [String.trim(v)]}
      {_k, _v} -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn {k, v} -> %{name: k, value: v} end)
  end

  defp parse_tags(_), do: nil

  @full_email_regex ~r/^(?:"?(?<name>[^"]*)"?\s)?<?(?<email>.+@[^>]+)>?$/

  defp parse_full_email(full_email) do
    case Regex.named_captures(@full_email_regex, String.trim(full_email)) do
      %{"email" => email, "name" => name} when is_binary(email) and is_binary(name) ->
        {String.trim(name), String.downcase(String.trim(email))}

      %{"email" => email} when is_binary(email) ->
        {nil, String.downcase(String.trim(email))}

      _ ->
        {nil, nil}
    end
  end

  defp message_valid?(%{recipient: nil}), do: {:error, :recipient_missing}
  defp message_valid?(%{}), do: :ok
end
