defmodule Passwordless.Email.EventDecoder do
  @moduledoc """
  Decodes email events from SES.
  """

  use Oban.Pro.Worker, queue: :queue_processor, max_attempts: 1, tags: ["event", "decoder"]

  import Ecto.Query

  alias Database.PrefixedUUID
  alias Database.Tenant
  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.Email
  alias Passwordless.Email.Adapter.SESParser
  alias Passwordless.EmailEvent
  alias Passwordless.EmailMessage
  alias Passwordless.EmailMessageMapping
  alias Passwordless.Repo

  @thresholds [
    rejects: 0.01,
    hard_bounces: 0.001,
    soft_bounces: 0.01,
    complaints: 0.001
  ]

  @impl true
  def process(%Oban.Job{args: %{"message" => message}}) when is_map(message) do
    with {:ok, parsed_message, parsed_event} <- SESParser.parse(message) do
      Repo.transact(fn ->
        with {:ok, app, message} <- get_message_by_external_id(parsed_message),
             {:ok, message} <- update_message(app, message, parsed_message),
             {:ok, event} <- create_message_event(app, message, parsed_event),
             {:ok, _event} <- guard_sending_reputation(app, message, event),
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
    |> EmailMessage.changeset(attrs, opts)
    |> Repo.update(opts)
  end

  defp get_message_by_external_id(%{external_id: external_id}) when is_binary(external_id) do
    case Repo.one(EmailMessageMapping.get_by_external_id(external_id)) do
      {%EmailMessageMapping{email_message_id: email_message_id}, %App{} = app} ->
        opts = [prefix: Tenant.to_prefix(app)]

        email_message_id =
          PrefixedUUID.uuid_to_slug(email_message_id, %{primary_key: true, prefix: EmailMessage.prefix()})

        case Repo.get(EmailMessage, email_message_id, opts) do
          %EmailMessage{} = message -> {:ok, app, message}
          _ -> {:error, :message_not_found}
        end

      _ ->
        {:error, :message_not_found}
    end
  end

  defp get_message_by_external_id(_), do: {:error, :message_not_found}

  defp guard_sending_reputation(%App{} = app, %EmailMessage{} = message, %EmailEvent{} = email_event) do
    case Repo.preload(message, [:email, :domain]) do
      %EmailMessage{email: %Email{} = email, domain: %Domain{} = domain} ->
        case event_verdict(email_event) do
          {:suspend, reason} ->
            with {:ok, _} <- Passwordless.opt_email_out(app, email, reason),
                 {:ok, _} <- maybe_suspend_app(app, domain),
                 do: {:ok, email_event}

          :pass ->
            {:ok, email_event}
        end

      _ ->
        {:error, :message_not_complete}
    end
  end

  defp event_verdict(%EmailEvent{kind: :bounce, bounce_type: :permanent}), do: {:suspend, "hard bounce"}
  defp event_verdict(%EmailEvent{kind: :bounce, bounce_type: :transient}), do: {:suspend, "soft bounce"}
  defp event_verdict(%EmailEvent{kind: :complaint}), do: {:suspend, "complaint"}
  defp event_verdict(%EmailEvent{kind: :reject}), do: {:suspend, "reject"}
  defp event_verdict(%EmailEvent{}), do: :pass

  defp maybe_suspend_app(%App{state: :active} = app, %Domain{} = domain) do
    if map_size(loast_statistics(app, domain)) > 0 do
      Passwordless.suspend_app(app)
    else
      {:ok, app}
    end
  end

  @two_weeks 2 |> Timex.Duration.from_weeks() |> Timex.Duration.to_seconds() |> trunc()

  defp loast_statistics(%App{} = app, %Domain{} = domain) do
    time_threshold = DateTime.add(DateTime.utc_now(), @two_weeks, :second)

    query =
      from ee in EmailEvent,
        prefix: ^Tenant.to_prefix(app),
        left_join: em in assoc(ee, :email_message),
        prefix: ^Tenant.to_prefix(app),
        where: em.domain_id == ^domain.id and ee.inserted_at >= ^time_threshold,
        select: %{
          total: count(ee.id),
          hard_bounces: ee.id |> count() |> filter(ee.kind == :bounce and ee.bounce_type == :permanent),
          soft_bounces: ee.id |> count() |> filter(ee.kind == :bounce and ee.bounce_type == :transient),
          complaints: ee.id |> count() |> filter(ee.kind == :complaint),
          rejects: ee.id |> count() |> filter(ee.kind == :reject)
        },
        group_by: em.domain_id

    case_result =
      case Repo.one(query) do
        %{
          total: total,
          hard_bounces: hard_bounces,
          soft_bounces: soft_bounces,
          complaints: complaints,
          rejects: rejects
        } ->
          %{
            hard_bounces: hard_bounces / total,
            soft_bounces: soft_bounces / total,
            complaints: complaints / total,
            rejects: rejects / total
          }

        _ ->
          %{
            hard_bounces: 0,
            soft_bounces: 0,
            complaints: 0,
            rejects: 0
          }
      end

    Enum.filter(case_result, fn {key, val} -> val >= @thresholds[key] end)
  end
end
