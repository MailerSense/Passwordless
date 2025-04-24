defmodule Passwordless.Email.EventDecoder do
  @moduledoc """
  Decodes email events from SES.
  """

  use Oban.Pro.Worker, queue: :queue_processor, max_attempts: 5, tags: ["event", "decoder"]

  alias Database.Tenant
  alias Passwordless.App
  alias Passwordless.Email.Adapter.SESParser
  alias Passwordless.EmailEvent
  alias Passwordless.EmailMessage
  alias Passwordless.EmailMessageMapping
  alias Passwordless.Repo

  @impl true
  def process(%Oban.Job{args: %{"message" => message}}) when is_map(message) do
    with {:ok, parsed_message, parsed_event} <- SESParser.parse(message) do
      Repo.transact(fn ->
        with {:ok, app, message} <- get_message_by_external_id(parsed_message),
             {:ok, message} <- update_message(app, message, parsed_message),
             {:ok, _event} <- create_message_event(app, message, parsed_event),
             do: :ok
      end)
    end
  end

  # Private

  defp create_message_event(%App{} = app, %EmailMessage{} = message, attrs) do
    opts = [prefix: Tenant.to_prefix(app)]

    message
    |> Ecto.build_assoc(:email_events)
    |> EmailEvent.changeset(attrs)
    |> Repo.insert(opts)
  end

  defp update_message(%App{} = app, %EmailMessage{} = message, attrs) do
    opts = [prefix: Tenant.to_prefix(app)]

    message
    |> EmailMessage.external_changeset(attrs)
    |> Repo.update(opts)
  end

  defp get_message_by_external_id(%{external_id: external_id}) when is_binary(external_id) do
    case Repo.one(EmailMessageMapping.get_by_external_id(external_id)) do
      {%EmailMessageMapping{email_message_id: email_message_id}, %App{} = app} ->
        opts = [prefix: Tenant.to_prefix(app)]

        case Repo.get(EmailMessage, email_message_id, opts) do
          %EmailMessage{} = message -> {:ok, app, message}
          _ -> {:error, :message_not_found}
        end

      _ ->
        {:error, :message_not_found}
    end
  end

  defp get_message_by_external_id(_), do: {:error, :message_not_found}
end
