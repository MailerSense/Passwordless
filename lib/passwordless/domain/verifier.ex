defmodule Passwordless.Identity.Verifier do
  @moduledoc """
  Verifies email identities by checking SES verification status and associated DNS records.
  """

  use Oban.Pro.Worker,
    queue: :identity_ops,
    max_attempts: 5,
    tags: ["email", "identities", "verifier"]

  alias MailerSense.Activity
  alias MailerSense.Cloud.Authenticator
  alias MailerSense.Cloud.Environment
  alias MailerSense.Cloud.Session
  alias MailerSense.Email.Identity
  alias MailerSense.Email.IdentityRecord
  alias MailerSense.Email.Provider
  alias MailerSense.Repo

  require Logger

  @chunk 100

  @impl true
  def process(%Oban.Job{meta: %{"cron" => true}}) do
    {to_check_ses, to_check_dns} =
      Identity.with_lessee()
      |> Repo.all()
      |> Enum.split_with(&Identity.pending_aws_verification?/1)

    check_ses(to_check_ses)

    :ok
  end

  # Private

  defp check_ses(domains) when is_list(domains) do
    Enum.each(domains, fn domain ->
      with {:ok, changesets} <- verify_ses(domain) do
        changesets
        |> Stream.map(&update_ses_verification/1)
        |> Stream.map(fn
          {:ok, %Identity{} = identity} ->
            identity

          {:error, error} ->
            Logger.warning("Failed to apply state trasition: #{inspect(error)}")
            nil
        end)
        |> Stream.reject(&is_nil/1)
        |> Stream.filter(&Identity.verified_by_aws?/1)
        |> Stream.map(&Repo.preload(&1, :records))
        |> Stream.map(&verify_records/1)
        |> Enum.each(fn
          {:ok, %Identity{state: :active} = identity} -> Activity.log(:email, :"identity.activate", identity)
          {:ok, %Identity{state: :unhealthy} = identity} -> Activity.log(:email, :"identity.become_unhealthy", identity)
          {:error, error} -> Logger.warning("Failed to verify DNS records: #{inspect(error)}")
          _ -> nil
        end)
      end

      :timer.sleep(:timer.seconds(1))
    end)
  end

  defp verify(%Identity{records: records} = identity) when is_list(records) do
    Enum.reduce(records, [], fn %IdentityRecord{} = record, changesets ->
      domain = IdentityRecord.domain_name(identity, record)

      case Util.DNS.resolve(domain, record.kind) do
        records when is_list(records) ->
          verified = Enum.any?(records, &match_record(%IdentityRecord{record | name: domain}, &1))

          if record.verified != verified do
            [IdentityRecord.changeset(record, %{verified: verified}) | changesets]
          else
            changesets
          end

        _ ->
          changesets
      end
    end)
  end

  defp update_records(%Identity{} = identity, changesets) when is_list(changesets) do
    result =
      changesets
      |> Enum.map(&Repo.update/1)
      |> Enum.all?(&match?({:ok, _}, &1))

    if result do
      {:ok, Repo.preload(identity, :records, force: true)}
    else
      {:error, :identity_record_insert_failed}
    end
  end

  defp apply_verification_transition(%Identity{state: state, verification: verification, records: records} = identity)
       when verification in ~w(aws_success all_records_verified some_records_missing)a and is_list(records) do
    all_verified? = Enum.all?(records, &IdentityRecord.is_verified?/1)

    new_verification =
      cond do
        verification == :aws_success and all_verified? -> :all_records_verified
        verification == :aws_success and not all_verified? -> :some_records_missing
        verification == :some_records_missing and all_verified? -> :all_records_verified
        verification == :all_records_verified and not all_verified? -> :some_records_missing
        true -> nil
      end

    new_state =
      cond do
        state == :inactive and new_verification == :all_records_verified -> :active
        state == :active and new_verification == :some_records_missing -> :unhealthy
        state == :unhealthy and new_verification == :all_records_verified -> :active
        true -> nil
      end

    changes = %{}

    changes =
      if new_verification && new_verification != verification,
        do: Map.put(changes, :verification, new_verification),
        else: changes

    changes = if new_state && new_state != state, do: Map.put(changes, :state, new_state), else: changes

    if map_size(changes) > 0 do
      identity
      |> Identity.changeset(changes)
      |> Repo.update()
    else
      {:ok, identity}
    end
  end

  defp apply_verification_transition(%Identity{} = identity), do: {:ok, identity}

  defp verify_ses(%Environment{} = env, identities) when is_list(identities) do
    with {:ok, session} <- Authenticator.get_session(env),
         {:ok, %{body: %{verification_attributes: attrs}}} when is_map(attrs) <-
           identities
           |> Enum.map(& &1.name)
           |> ExAws.SES.get_identity_verification_attributes()
           |> ExAws.request(Session.request_opts(session)) do
      changesets =
        Enum.reduce(identities, [], fn %Identity{} = identity, changesets ->
          with {:ok, %{"VerificationStatus" => status}} when is_binary(status) <- Map.fetch(attrs, identity.name),
               {:ok, new_verification} <- Map.fetch(Identity.aws_verification_states(), status),
               true <- new_verification != identity.verification do
            [Identity.changeset(identity, %{verification: new_verification}) | changesets]
          else
            _ -> changesets
          end
        end)

      {:ok, changesets}
    end
  end

  defp verify_records(%Identity{} = identity) do
    case verify(identity) do
      [_ | _] = changesets ->
        Repo.transact(fn ->
          with {:ok, identity} <- update_records(identity, changesets),
               do: apply_verification_transition(identity)
        end)

      _ ->
        {:ok, identity}
    end
  end

  defp update_ses_verification(%Ecto.Changeset{} = changeset) do
    Repo.transact(fn ->
      with {:ok, identity} <- Repo.update(changeset),
           do: apply_verification_transition(identity)
    end)
  end

  defp match_record(
         %IdentityRecord{kind: :mx, name: name, value: value, priority: priority},
         {:mx, name, _ttl, {priority, value}}
       )
       when is_binary(name) and is_integer(priority) and is_binary(value),
       do: true

  defp match_record(%IdentityRecord{kind: :txt, name: name, value: value}, {:txt, name, _ttl, entries})
       when is_binary(name) and is_binary(value),
       do: Enum.member?(entries, value)

  defp match_record(%IdentityRecord{kind: :cname, name: name, value: value}, {:cname, name, _ttl, value})
       when is_binary(name) and is_binary(value),
       do: true

  defp match_record(%IdentityRecord{}, _record), do: false
end
