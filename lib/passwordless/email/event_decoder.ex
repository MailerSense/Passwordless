defmodule Passwordless.Email.EventDecoder do
  @moduledoc false

  alias Passwordless.Email.LogParser

  def create_message_from_event(raw_message) when is_map(raw_message) do
    with {:ok, parsed_log, parsed_message, parsed_event} <- LogParser.parse(raw_message) do
      Repo.transact(fn ->
        with {:ok, message} <- update_message_from_event(parsed_message),
             {:ok, event} <- create_message_event(parsed_event),
             {:ok, log} <- Activity.log(:email, message, event, parsed_log),
             {:ok, _suppression} <- Guardian.check(log),
             do: {:ok, message}
      end)
    end
  end

  def create_message_from_event(_), do: {:error, :message_parse_failed}

  # Private

  defp create_message_event(attrs) when is_map(attrs) do
    %MessageEvent{}
    |> MessageEvent.changeset(attrs)
    |> Repo.insert()
  end

  defp update_message_from_event(%{external_id: external_id} = attrs) when is_binary(external_id) do
    case Repo.one(Message.get_by_external_id(external_id)) do
      %Message{} = message ->
        message
        |> Message.external_changeset(attrs)
        |> Repo.update()

      _ ->
        {:error, :message_not_found}
    end
  end

  defp update_message_from_event(_), do: {:error, :message_not_found}
end
