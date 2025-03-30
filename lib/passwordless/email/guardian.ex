defmodule MailerSense.Email.Guardian do
  @moduledoc """
  Guards the reputation of email contacts based on the email activity.
  """

  import Ecto.Query

  alias MailerSense.Activity
  alias MailerSense.Activity.Log
  alias MailerSense.Audience
  alias MailerSense.Audience.Contact
  alias MailerSense.Email
  alias MailerSense.Email.Event
  alias MailerSense.Email.Identity
  alias MailerSense.Repo

  @window 1000
  @faulty_actions ~w(
    message.bounce
    message.reject
    message.complain
    message.unsubscribe
  )a
  @non_notification_actions ~w(
    message.submit
    message.suspend
  )a
  @thresholds [
    unsubscribe: 0.01,
    hard_bounce: 0.001,
    soft_bounce: 0.01,
    spam_complaint: 0.001
  ]

  def check(%Log{
        org_id: org_id,
        domain: :email,
        action: :"message.bounce",
        event: %Event{bounce_type: :permanent},
        email_identity_id: identity_id,
        audience_contact_id: contact_id
      })
      when is_binary(org_id) and is_binary(identity_id) and is_binary(contact_id),
      do: suppress_contact(org_id, contact_id, identity_id, :hard_bounce)

  def check(%Log{
        org_id: org_id,
        domain: :email,
        action: :"message.bounce",
        event: %Event{bounce_type: :transient},
        email_identity_id: identity_id,
        audience_contact_id: contact_id
      })
      when is_binary(org_id) and is_binary(identity_id) and is_binary(contact_id),
      do: check_contact(org_id, contact_id, identity_id)

  def check(%Log{
        org_id: org_id,
        domain: :email,
        action: :"message.complain",
        event: %Event{},
        email_identity_id: identity_id,
        audience_contact_id: contact_id
      })
      when is_binary(org_id) and is_binary(identity_id) and is_binary(contact_id),
      do: suppress_contact(org_id, contact_id, identity_id, :spam_complaint)

  def check(%Log{
        org_id: org_id,
        domain: :email,
        action: :"message.unsubscribe",
        email_identity_id: identity_id,
        audience_contact_id: contact_id
      })
      when is_binary(org_id) and is_binary(identity_id) and is_binary(contact_id),
      do: check_contact(org_id, contact_id, identity_id)

  def check(%Log{} = log), do: {:ok, log}

  # Private

  defp suppress_contact(org_id, contact_id, identity_id, reason) do
    with %Contact{} = contact <- Audience.get(contact_id),
         %Identity{} = identity <- Email.get_identity(identity_id) do
      Repo.transact(fn ->
        with {:ok, suppression} <- insert_contact_suppression(contact, identity, reason),
             {:ok, _identity} <- maybe_place_identity_under_review(identity, compute_fault_rates(org_id)),
             do: {:ok, suppression}
      end)
    end
  end

  defp check_contact(org_id, contact_id, identity_id) do
    with %Contact{} = contact <- Audience.get(contact_id),
         %Identity{} = identity <- Email.get_identity(identity_id) do
      maybe_place_identity_under_review(identity, compute_fault_rates(org_id))
    end
  end

  defp insert_contact_suppression(%Contact{} = contact, %Identity{} = identity, reason) do
    with {:ok, suppression} <- Audience.suppress_contact(contact, identity, reason),
         {:ok, _log} <- Activity.log(:audience, :"contact.suppress", contact),
         do: {:ok, suppression}
  end

  defp maybe_place_identity_under_review(%Identity{} = identity, state) when map_size(state) > 0 do
    with {:ok, identity} <- Email.place_identity_under_review(identity),
         {:ok, _log} <- Activity.log(:email, :"identity.place_under_review", identity, state),
         do: {:ok, identity}
  end

  defp maybe_place_identity_under_review(%Identity{} = identity, _state), do: {:ok, identity}

  defp compute_fault_rates(org_id) when is_binary(org_id) do
    state = %{
      unsubscribe: 0,
      hard_bounce: 0,
      soft_bounce: 0,
      spam_complaint: 0
    }

    notifications =
      org_id
      |> get_email_notifications()
      |> Repo.all()

    if Enum.empty?(notifications) do
      state
    else
      notifications
      |> Enum.filter(&is_faulty?/1)
      |> Enum.reduce(state, &record_fault/2)
      |> Map.new(fn {key, val} -> {key, val / Enum.count(notifications)} end)
      |> review_faults()
    end
  end

  defp get_email_notifications(org_id) when is_binary(org_id) do
    from l in Log,
      where:
        l.org_id == ^org_id and
          l.domain == :email and
          l.action not in @non_notification_actions,
      limit: ^@window,
      preload: [:email_event],
      order_by: [desc: l.id]
  end

  defp is_faulty?(%Log{action: action}) when action in @faulty_actions, do: true
  defp is_faulty?(%Log{}), do: false

  defp record_fault(%Log{domain: :email, action: :"message.bounce", event: %Event{bounce_type: :permanent}}, state)
       when is_map(state) do
    Map.update(state, :hard_bounce, 1, &(&1 + 1))
  end

  defp record_fault(%Log{domain: :email, action: :"message.bounce", event: %Event{bounce_type: :transient}}, state)
       when is_map(state) do
    Map.update(state, :soft_bounce, 1, &(&1 + 1))
  end

  defp record_fault(%Log{domain: :email, action: :"message.complain"}, state) when is_map(state) do
    Map.update(state, :spam_complaint, 1, &(&1 + 1))
  end

  defp record_fault(%Log{domain: :email, action: :"message.unsubscribe"}, state) when is_map(state) do
    Map.update(state, :unsubscribe, 1, &(&1 + 1))
  end

  defp review_faults(state) do
    Enum.filter(state, fn {key, val} -> val >= @thresholds[key] end)
  end
end
