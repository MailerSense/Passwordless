defmodule Passwordless.Email.EventDecoder do
  @moduledoc false

  alias Passwordless.App
  alias Passwordless.Email.Guardian
  alias Passwordless.Email.SESParser
  alias Passwordless.EmailEvent
  alias Passwordless.EmailMessage
  alias Passwordless.EmailMessageMapping
  alias Passwordless.Repo

  def create_message_from_event(raw_message) when is_map(raw_message) do
    with {:ok, parsed_message, parsed_event} <- SESParser.parse(raw_message) do
      Repo.transact(fn ->
        with {:ok, app, message} <- get_message_by_external_id(parsed_message),
             {:ok, message} <- update_message(app, message, parsed_message),
             {:ok, event} <- create_message_event(app, message, parsed_event),
             do: {:ok, message, event}
      end)
    end
  end

  def create_message_from_event(_), do: {:error, :message_parse_failed}

  # Private

  defp create_message_event(%App{} = app, %EmailMessage{} = message, attrs) do
    opts = [prefix: Database.Tenant.to_prefix(app)]

    message
    |> Ecto.build_assoc(:email_events)
    |> EmailEvent.changeset(attrs)
    |> Repo.insert(opts)
  end

  defp update_message(%App{} = app, %EmailMessage{} = message, attrs) do
    opts = [prefix: Database.Tenant.to_prefix(app)]

    message
    |> EmailMessage.external_changeset(attrs)
    |> Repo.update(opts)
  end

  defp get_message_by_external_id(%{external_id: external_id}) when is_binary(external_id) do
    case Repo.one(EmailMessageMapping.get_by_external_id(external_id)) do
      {%EmailMessageMapping{email_message_id: email_message_id}, %App{} = app} ->
        opts = [prefix: Database.Tenant.to_prefix(app)]

        case Repo.get(EmailMessage, email_message_id, opts) do
          %EmailMessage{} = message ->
            {:ok, app, Repo.preload(message, [:domain, {:email, [:actor]}])}

          _ ->
            {:error, :message_not_found}
        end

      _ ->
        {:error, :message_not_found}
    end
  end

  defp get_message_by_external_id(_), do: {:error, :message_not_found}
end
