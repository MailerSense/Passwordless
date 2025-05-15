defmodule Passwordless.Domain.Verifier do
  @moduledoc """
  Verifies email domains by checking SES verification status and associated DNS records.
  """

  use Oban.Pro.Worker, queue: :domain, tags: ["email", "domains", "verifier"]

  alias Passwordless.Domain
  alias Passwordless.DomainRecord
  alias Passwordless.Repo

  require Logger

  @chunk 100

  @impl true
  def process(%Oban.Job{meta: %{"cron" => true}}) do
    {to_check_ses, to_check_dns} =
      Domain.get_not_verified()
      |> Repo.all()
      |> Enum.split_with(&Domain.pending_aws_state?/1)

    to_check_dns = Repo.preload(to_check_dns, :records)

    check_ses(to_check_ses)
    check_dns(to_check_dns)

    :ok
  end

  # Private

  defp check_ses(domains) do
    domains
    |> Enum.chunk_every(@chunk)
    |> Enum.each(fn domains ->
      with {:ok, changesets} <- verify_ses(domains) do
        changesets
        |> Stream.map(fn changeset ->
          Repo.transact(fn ->
            with {:ok, domain} <- Repo.update(changeset), do: apply_state_transition(domain)
          end)
        end)
        |> Stream.map(fn
          {:ok, %Domain{} = domain} ->
            domain

          {:error, error} ->
            Logger.warning("Failed to apply state trasition: #{inspect(error)}")
            nil
        end)
        |> Stream.reject(&is_nil/1)
        |> Stream.filter(&Domain.verified_by_aws?/1)
        |> Stream.map(&Repo.preload(&1, :records))
        |> Stream.map(&verify_records/1)
        |> Enum.to_list()
      end

      :timer.sleep(:timer.seconds(1))
    end)
  end

  defp check_dns(domains) when is_list(domains) do
    Enum.each(domains, &verify_records/1)
  end

  defp verify(%Domain{records: records} = domain) when is_list(records) do
    Enum.reduce(records, [], fn %DomainRecord{} = record, changesets ->
      domain_name = DomainRecord.domain_name(domain, record)

      case Util.DNS.resolve(domain_name, record.kind) do
        records when is_list(records) ->
          verified =
            Enum.any?(records, &match_record(%DomainRecord{record | name: domain_name}, &1))

          if record.verified != verified do
            [DomainRecord.changeset(record, %{verified: verified}) | changesets]
          else
            changesets
          end

        _ ->
          changesets
      end
    end)
  end

  defp verify_ses(domains) do
    with {:ok, %{body: %{verification_attributes: attrs}}} when is_map(attrs) <-
           domains
           |> Enum.map(& &1.name)
           |> ExAws.SES.get_identity_verification_attributes()
           |> ExAws.request() do
      changesets =
        Enum.reduce(domains, [], fn %Domain{} = domain, changesets ->
          with {:ok, %{"VerificationStatus" => status}} when is_binary(status) <-
                 Map.fetch(attrs, domain.name),
               {:ok, new_state} <- Map.fetch(Domain.aws_verification_states(), status),
               true <- new_state != domain.state do
            [Domain.changeset(domain, %{state: new_state}) | changesets]
          else
            _ -> changesets
          end
        end)

      {:ok, changesets}
    end
  end

  defp verify_records(%Domain{} = domain) do
    case verify(domain) do
      [_ | _] = changesets ->
        Repo.transact(fn ->
          with {:ok, domain} <- update_records(domain, changesets),
               do: apply_state_transition(domain)
        end)

      _ ->
        {:ok, domain}
    end
  end

  defp update_records(%Domain{} = domain, changesets) when is_list(changesets) do
    result =
      changesets
      |> Enum.map(&Repo.update/1)
      |> Enum.all?(&match?({:ok, _}, &1))

    if result do
      {:ok, Repo.preload(domain, :records, force: true)}
    else
      {:error, :domain_record_insert_failed}
    end
  end

  defp apply_state_transition(%Domain{state: state, records: records} = domain)
       when state in ~w(aws_success all_records_verified some_records_missing)a and is_list(records) do
    all_verified? = Enum.all?(records, &DomainRecord.verified?/1)

    changes =
      cond do
        state == :aws_success and all_verified? -> %{state: :all_records_verified}
        state == :aws_success and not all_verified? -> %{state: :some_records_missing}
        state == :some_records_missing and all_verified? -> %{state: :all_records_verified}
        state == :all_records_verified and not all_verified? -> %{state: :some_records_missing}
        true -> %{}
      end

    other_changes =
      case changes do
        %{state: :all_records_verified} -> %{verified: true}
        %{state: :all_records_verified} -> %{verified: false}
        _ -> %{}
      end

    changes = Map.merge(changes, other_changes)

    if map_size(changes) > 0 do
      domain
      |> Domain.changeset(changes)
      |> Repo.update()
    else
      {:ok, domain}
    end
  end

  defp apply_state_transition(%Domain{} = domain), do: {:ok, domain}

  defp match_record(
         %DomainRecord{kind: :mx, name: name, value: value, priority: priority},
         {:mx, name, _ttl, {priority, value}}
       )
       when is_binary(name) and is_integer(priority) and is_binary(value),
       do: true

  defp match_record(%DomainRecord{kind: :txt, name: name, value: value} = record, {:txt, name, _ttl, entries})
       when is_binary(name) and is_binary(value),
       do:
         if(DomainRecord.dmarc?(record),
           do: Enum.any?(entries, &DomainRecord.dmarc?(%DomainRecord{kind: :txt, value: &1})),
           else: Enum.member?(entries, value)
         )

  defp match_record(%DomainRecord{kind: :cname, name: name, value: value}, {:cname, name, _ttl, value})
       when is_binary(name) and is_binary(value),
       do: true

  defp match_record(%DomainRecord{}, _record), do: false
end
